_ = require 'lodash'
path = require 'path'
url = require 'url'

PLATFORM = 'instagram'

PATH = path.resolve __dirname, '..'

module.exports = (System, API) ->
  Identity = System.getModel 'Identity'

  Setup =
    setup: (req, res, next) ->
      step = req.params.step
      if step == "app" or step == "" or !step # Default is Step 1: /admin/instagram/app
        Setup.setupApp req, res, next
      else if step == "connect"
        Setup.setupConnect req, res, next
      else
        next()

    setupApp: (req, res, next) ->
      API.getSettings (err, settings) ->
        if req?.body?.settings and req.body.settings.instagram
          # Process form
          if !settings
            settings = {}

          for k, v of req.body.settings.instagram
            settings[k] = v

          API.updateSettings settings, (err) ->
            throw err if err

            # Done with this step. Continue!
            res.redirect '/admin/instagram/connect'
        else
          # Show the page for this step
          res.render 'app',
            settings:
              instagram: settings

    setupConnect: (req, res, next) ->
      API.getSettings (err, settings) ->
        isSetup = false
        if settings?.client_secret and settings.access_token
          isSetup = true

        Identity.getMe (err, me) ->
          throw err if err

          instagramMe = _.find me.linked, (identity) -> identity.platform == 'instagram'
          console.log me
          console.log instagramMe

          # Show the page for this step
          opt =
            title: "Connect to Instagram"
            settings:
              instagram: settings
            isSetup: isSetup
            me: instagramMe
          res.render 'connect', opt

    disconnect: (req, res, next) ->
      API.getSettings (err, settings) ->
        if settings?
          settings.access_token = null
        API.updateSettings settings, (err) ->
          throw err if err
          res.redirect '/admin/instagram/connect'

    oauth: (req, res, next) ->
      console.log "Instagram: starting oauth"
      path = url.parse req.url, true

      API.getSettings (err, settings) ->
        igSettings =
          client_id: settings.client_id
          client_secret: settings.client_secret
        ig = API.getInstagram igSettings
        res.writeHead 303,
          location: ig.get_authorization_url settings.callback_url, {scope: "comments likes"}
        res.end()

    auth: (req, res, next) ->
      console.log "Instagram: auth received..."
      API.getSettings (err, settings) ->
        igSettings =
          client_id: settings.client_id
          client_secret: settings.client_secret
        ig = API.getInstagram igSettings
        throw err if err

        ig.authorize_user req.query.code, settings.callback_url, (err, result) ->
          if err
            console.log 'authorize_user failed', ig
            console.error err
            res.send err
          else
            settings.access_token = result.access_token if result?.access_token?
            #console.log("Saving Instagram access_token: "+settings.access_token)
            API.updateSettings settings, (err) ->
              API.getUser 'self', (err, identity) ->
                throw err if err
                Identity.getMe (err, me) ->
                  throw err if err
                  me.link identity, (err) ->
                    throw err if err
                    API.feed ->
                      res.redirect '/admin/instagram/connect'
