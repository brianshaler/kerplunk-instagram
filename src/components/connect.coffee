React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    Avatar = @props.getComponent 'kerplunk-stream:avatar'
    DOM.section
      className: 'content admin-panel'
    ,
      DOM.p null,
        'We will now authenticate your user account to the app...'
      DOM.p null,
        DOM.a
          href: '/admin/instagram/oauth'
        , 'Click here to authenticate'
      if @props.settings?.instagram?.identity
        DOM.div null,
          DOM.h4 {}, 'Your account has been connected!'
          Avatar
            identity: @props.settings?.instagram?.identity
      else
        null
