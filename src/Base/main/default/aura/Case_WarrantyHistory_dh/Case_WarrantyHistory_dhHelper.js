({
	fetchHistory : function( component )
  {
    console.log('helper');
    var action = component.get('c.fetchWarrantyHistory');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    return this.actionHandler.call(this, action, false );
	},

  actionHandler: function( action, deserialize )
  {
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback(self, function(response) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          var result = deserialize ? JSON.parse( response.getReturnValue() ) :
                                     response.getReturnValue();
          resolve( result );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
          var errors = response.getError();
          if (errors) {
              if (errors[0] && errors[0].message) {
                  reject("Error message: " +
                           errors[0].message);
              }
          } else {
              reject("Unknown error");
          }
        }
      });

      $A.enqueueAction( action );
    });
  }
})