instagramApi = require('instagram-node').instagram()

PLATFORM = 'instagram'

module.exports = (System) ->
  ActivityItem = System.getModel 'ActivityItem'
  Identity = System.getModel 'Identity'

  API =
    getSettings: (next) ->
      System.getSettings (err, settings) ->
        next err, settings

    updateSettings: (settings, next) ->
      System.updateSettings settings, (err, settings) ->
        next err, settings

    prep: (next) ->
      API.getSettings (err, settings) ->
        return next err if err
        ig = API.getInstagram settings
        next null, settings, ig

    getInstagram: (settings) ->
      params =
        client_id: settings.client_id
        client_secret: settings.client_secret
        redirect_uri: settings.callback_url
      if settings.access_token
        params.access_token = settings.access_token
      console.log 'params', params
      if params.client_id and params.client_secret
        instagramApi.use params
      instagramApi

    feed: (next) ->
      API.prep (err, settings, ig) ->
        return next err if err

        if !settings?.access_token
          # 'Couldn't find Instagram settings. Have you set it up yet?'
          console.log 'No settings?', settings
          return next new Error 'Instagram not configured?'

        params =
          limit: 100
        if settings.timelineMinId?
          params.min_id = settings.timelineMinId
        params.access_token = settings.access_token
        #console.log 'instagram params', params

        processFeed = (err, posts) ->
          console.log "processing #{posts?.length} instagram posts", err
          if err
            console.error err
            return next err
          if posts?.length > 0
            settings.timelineMinId = posts[0].id
          System.updateSettings settings, (err) ->
            API.processPosts posts, next

        console.log 'Instagram: fetching posts', params
        ig.user_self_feed params, processFeed

    getUser: (userId, next) ->
      API.prep (err, settings, ig) ->
        return next err if err
        unless settings?.access_token
          return next new Error 'Instagram not configured?'
        ig.user userId, (err, user) ->
          return next err if err

          user.platformId = user.id
          user.firstName = user.full_name.split(' ').slice(0,-1).join ' '
          unless user.firstName == user.full_name
            user.lastName = user.full_name.split(' ').slice(-1).join ' '
          user.fullName = user.full_name
          user.nickName = user.username
          user.profileUrl = "https://instagram.com/#{user.username}"

          data =
            guid: ["#{PLATFORM}-#{user.id}"]
            platform: [PLATFORM]
            # platformId: user.id
            firstName: user.firstName
            lastName: user.lastName
            fullName: user.fullName
            nickName: user.nickName
            # url: user.profileUrl
            photo: [
              {url: user.profile_picture}
            ]
            data:
              instagram: user

          Identity.getOrCreate data, (err, identity) ->
            photoFound = false
            identity.photo.forEach (photo) ->
              if photo.url == user.profile_picture
                photoFound = true
            if !photoFound
              identity.photo.push url: user.profile_picture

            identity.save (err) ->
              next err, identity

    processPosts: (posts, next) ->
      processNextPost = (err) ->
        return next err if err
        return next null unless posts.length > 0
        #console.log "post: #{posts.length}"
        API.processPost posts.pop(), (err) ->
          processNextPost err
      processNextPost()

    processPost: (post, next) ->
      #console.log 'Processing post: ', post.id

      guid = "#{PLATFORM}-#{post.id}"

      message = ''
      if post.caption and post.caption.text and post.caption.text.length > 0
        message = post.caption.text
      else
        message = 'Posted a photo ' + post.link

      lat = 0
      lng = 0
      if post.location?.latitude and post.location.longitude
        lat = parseFloat post.location.latitude
        lng = parseFloat post.location.longitude

      image = {}
      keys = ['standard_resolution', 'thumbnail', 'low_resolution']
      image.type = 'photo'
      image.sizes = []
      for size in keys
        image.sizes.push
          url: post.images[size].url
          width: post.images[size].width
          height: post.images[size].height

      user = post.user
      user.platformId = user.id
      user.firstName = user.full_name.split(' ').slice(0,-1).join ' '
      unless user.firstName == user.full_name
        user.lastName = user.full_name.split(' ').slice(-1).join ' '
      user.fullName = user.full_name
      user.nickName = user.username
      user.profileUrl = "https://instagram.com/#{user.username}"

      data =
        identity:
          guid: ["#{PLATFORM}-#{user.id}"]
          platform: [PLATFORM]
          # platformId: user.id
          firstName: user.firstName
          lastName: user.lastName
          fullName: user.fullName
          nickName: user.nickName
          photo: [
            {url: user.profile_picture}
          ]
          data:
            instagram: user
        item:
          guid: "#{PLATFORM}-#{post.id}"
          platform: PLATFORM
          platformId: post.id
          message: message
          media: [image]
          postedAt: new Date post.created_time * 1000
          data: post
      data.item.location = [lng, lat] if lng != 0 and lat != 0

      ActivityItem.getOrCreate data, (err, activityItem, identity) ->
        return next err if err
        console.log 'activityitem saved', activityItem._id, activityItem.guid

        identity.attributes = {} if !identity.attributes?
        identity.attributes.isFriend = true
        identity.updatedAt = new Date()

        photoFound = false
        identity.photo.forEach (photo) ->
          if photo.url == post.user.profile_picture
            photoFound = true
        if !photoFound
          identity.photo.push url: post.user.profile_picture

        identity.save (err) ->
          return next err if err
          activityItem.save (err) ->
            return next err if err
            next null, activityItem, identity
