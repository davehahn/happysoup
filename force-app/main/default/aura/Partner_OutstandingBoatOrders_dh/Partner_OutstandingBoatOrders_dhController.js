({
	doInit : function(component, event, helper)
  {
    helper.checkPermission( component )
    .then(
      $A.getCallback( function( result ) {
        console.log( result );
        component.set('v.hasPermission', result );
        return helper.fetchNumbers( component );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    helper.fetchNumbers( component )
    .then(
      $A.getCallback( function( result ) {
        if( result === null )
          return;
        component.set('v.boats', result.boats );
        component.set('v.trailers', result.trailers );
        component.set('v.isLoaded', true );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
	},

  orderDetailsClick: function( component, event, helper )
  {
    var orderType = event.currentTarget.dataset.orderType;
    helper.loadDetailsModal( component, orderType );
  }
})