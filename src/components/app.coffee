React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    DOM.section
      className: 'content admin-panel'
    ,
      DOM.h1 {}, 'Instagram Configuration'
      DOM.p null,
        'Copy the details from your Instagram App, which you can find or create at '
        DOM.a
          href: 'https://instagr.am/developer/clients/manage/'
          target: '_blank'
        , 'https://instagr.am/developer/clients/manage/'
      DOM.p null,
        DOM.form
          method: 'post'
          action: '/admin/instagram/app'
        ,
          DOM.table null,
            DOM.tr null,
              DOM.td null,
                DOM.strong null, 'Client ID:'
              DOM.td null,
                DOM.input
                  name: 'settings[instagram][client_id]'
                  defaultValue: @props.settings?.instagram?.client_id
            DOM.tr null,
              DOM.td null,
                DOM.strong null, 'Client Secret:'
              DOM.td null,
                DOM.input
                  name: 'settings[instagram][client_secret]'
                  defaultValue: @props.settings?.instagram?.client_secret
            DOM.tr null,
              DOM.td null,
                DOM.strong null, 'Callback URL:'
              DOM.td null,
                DOM.input
                  name: 'settings[instagram][callback_url]'
                  defaultValue: @props.settings?.instagram?.callback_url
            DOM.tr null,
              DOM.td null, ''
              DOM.td null,
                DOM.input
                  type: 'submit'
                  value: 'Save & Next'
