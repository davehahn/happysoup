/**
 * Created by dave on 2020-09-11.
 */

({
  doInit: function( component, event )
  {
    console.log('Utility_CometD.doInit()');
    const sessionId = component.get('v.sessionId');
    const url = window.location.protocol + '//' + window.location.hostname + '/cometd/49.0/'
    console.log(`Utility_CometD.sessionId = ${sessionId}`);
    console.log(`url = ${url}`);
    console.log('wtf');
    var cometd = new window.org.cometd.CometD();
    console.log(cometd);

    cometd.configure({
      url: url,
      requestHeaders: { Authorization: 'OAuth ' + sessionId},
      appendMessageTypeToURL : false,
      logLevel: 'debug'
    });

    cometd.websocketEnabled = false;

    cometd.handshake( $A.getCallback( function(status) {
      if(status.successful)
      {
        // Successfully connected to the server.
        // Now it is possible to subscribe or send messages
        console.log('Successfully connected to server');
        component.set('v.cometd', cometd);
      }
      else
      {
        /// Cannot handshake with the server, alert user.
        console.error('Error in handshaking: ' + JSON.stringify(status));
      }
    }));
    console.log('end of it');
  },

  subscribe: function( component, event )
  {
    const params = event.getParam('arguments');
    var cometd = component.get('v.cometd');
    let channel, replayId, callback;
    if( params )
    {
      channel = params.channel;
      replayId = params.replayId;
      callback = params.callback;
      return new Promise( (resolve, reject) => {
        var subscription = cometd.subscribe(
          '/event/Partner_Program_Event__e',
          $A.getCallback( (message) => {
            callback( message );
          })
        );
        resolve( subscription );
      });
    }
  },

  unsubscribe: function( component, event )
  {
    const params = event.getParam('arguments');
    var cometd = component.get('v.cometd');
    let subscription, callback;
    if( params )
    {
      subscription = params.subscription;
      callback = params.callback;
      cometd.unsubscribe(
        subscription,
        $A.getCallback( response => {
          callback( response );
        })
      );
    }
  }
});