({
  doInit: function( component, event, helper )
  {
    if( component.get('v.partnerCount') === 1 )
    {
      component.set('v.zoomLevel', 10 );
    }
  },

  findClosestDealer: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    spinner.toggle();
    helper.doClosestDealer( component )
    .then(
      $A.getCallback( function( results ) {
        console.log( results );
        component.set('v.mapMarkers', results.mapMarkers);
        component.set('v.originAddress', results.origin_address );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  handleCountChange:function( component, event, helper )
  {
    console.log( 'handleCountChange' );
    helper.plotMarkers( component );
  },

  navToAccount: function(component, event)
  {
    event.preventDefault();
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
        "recordId": component.get("v.result").id
    });
    navEvt.fire();
  }
})