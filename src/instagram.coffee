SetupModule = require './setup'
APIModule = require './api'

module.exports = (System) ->
  API = APIModule System
  Setup = SetupModule System, API

  globals:
    public:
      nav:
        Admin:
          'Social Networks':
            Instagram:
              'App Settings': '/admin/instagram/app'
              'Connect Account': '/admin/instagram/connect'
      editStreamConditionOptions:
        isInstagramTrue:
          description: 'instagram photos only'
          where:
            platform: 'instagram'
        isInstagramFalse:
          description: 'no instagram photos'
          where:
            platform:
              '$ne': 'instagram'
      activityItem:
        icons:
          instagram: '/plugins/kerplunk-instagram/images/Instagram_logo.png'

  routes:
    admin:
      '/admin/instagram/:step': 'setup'
      '/admin/instagram': 'index'
      '/admin/instagram/disconnect': 'disconnect'
      '/admin/instagram/oauth': 'oauth'
      '/admin/instagram/auth': 'auth'
      '/admin/instagram/timeline': 'timeline'

  handlers:
    setup: Setup.setup
    index: (req, res) -> res.redirect '/admin/instagram/app'
    disconnect: Setup.disconnect
    oauth: Setup.oauth
    auth: Setup.auth
    timeline: (req, res, next) ->
      API.feed (err) ->
        console.error err if err
        return next err if err
        res.send 'Done.'

  crons: [
    {
      frequency: 120
      task: (finished) ->
        console.log 'get instagram feed'
        API.feed (err) ->
          console.log err if err
          finished()
    }
  ]
