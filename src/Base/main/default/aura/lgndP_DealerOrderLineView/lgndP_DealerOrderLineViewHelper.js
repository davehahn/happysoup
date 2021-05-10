({
	fetchData : function( component )
  {
    var self = this,
        groupId = component.get('v.orderGroupId')
        action = component.get('c.viewDealerLineItem');

    action.setParams({
      groupId: groupId
    });

    return new Promise( function( resolve, reject ) {

      action.setCallback( self, function( response ) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
          resolve( JSON.parse( response.getReturnValue() ) );
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
        //self.functions.toggleSpinner( component, false );
      });

      $A.enqueueAction( action );

    });

	}
})