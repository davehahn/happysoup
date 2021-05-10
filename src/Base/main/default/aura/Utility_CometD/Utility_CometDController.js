/**
 * Created by dave on 2020-09-11.
 */

({
  subscribe: function( component, event, helper )
  {
    const params = event.getParam('arguments');
    let channel, replayId, callback;

    if( params )
    {
      return new Promise( (resolve, reject) => {
        channel = params.channel;
        replayId = params.replayId;
        callback = params.callback;
        helper.connect( component )
        .then( (cometd) => {
          var subscription = cometd.subscribe(
            channel,
            $A.getCallback( (message) =>
            {
              callback( message );
            })
          );
          resolve( subscription );
        });
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