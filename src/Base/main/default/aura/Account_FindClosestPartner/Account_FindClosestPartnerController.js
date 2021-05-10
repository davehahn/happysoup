({
  doInit: function( component, event, helper )
  {
    if( component.get('v.partnerCount') === 1 )
    {
      component.set('v.zoomLevel', 10 );
    }
  },

  checkForEnter: function( component, event, helper )
  {
    if( event.which === 13 )
    {
      helper.findClosestDealer( component );
    }
  },

  findClosestDealer: function( component, event, helper )
  {
    helper.findClosestDealer( component );
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