({
  doInit: function( component, event, helper )
  {

  },

	afterScripts: function(component, event, helper)
  {
    helper.testCometD( component );
    var navMap = ['order-details',
                  'build-boat',
                  'review-container'];
    component.set('v.currentAction', 0);
    component.set('v.navMap', navMap);
    component.find("orderDetails--Cmp").doInit();
  },

  handleOrderCancel: function( component, event, helper )
  {
    helper.toggleIndicator( component, 'Cancelling Order')
    helper.cancelOrder( component )
    .then(
      $A.getCallback( function() {
        helper.navigateHome();
      }),
      $A.getCallback( function( err ) {
        LightningUtilis.errorToast( err );
      })
    );
  },

  nextStage: function( component, event, helper)
  {
    var navMap = component.get("v.navMap"),
        current = component.get("v.currentAction"),
        params = {
          navigateTo: current + 1,
          firedBy: current
        };

    if( navMap.length === params.navigateTo )
      return false;

    helper.handleStageChange(params, component);
  },

  previousStage: function( component, event, helper )
  {
    var current = component.get("v.currentAction"),
        params = {
          navigateTo: current -1,
          firedBy: current
        };

    if( params.navigateTo < 0  )
      return false;

    helper.handleStageChange( params, component);
  },

  handleNav: function( component, event, helper )
  {
    var params = event.getParams();
     helper.handleStageChange( params, component);
  },

  handleIndicator: function( component, event, helper )
  {
    var params = event.getParams(),
        msg = params.message;
    helper.toggleIndicator( component, msg );
//    if( params.isBusy )
//      $A.util.removeClass( indicator, 'toggle' );
//    else
//      $A.util.addClass( indicator, 'toggle' );
  }
})