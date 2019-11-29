({
  getUserType: function( component )
  {
    var action = component.get( 'c.getUserType' );
    return this.actionHandler.call( this, action );
  },


	fetchDealerOrder : function( component )
  {
    var recordId = component.get('v.recordId'),
        action = component.get('c.fetchDealerOrder');

    action.setParams({
      'recordId': recordId
    });

    return this.actionHandler.call( this, action );

	},

  actionHandler: function( action )
  {
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          resolve( response.getReturnValue() );
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