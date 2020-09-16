({
  doInit: function( component, event, helper )
  {

  },

	afterScripts: function(component, event, helper)
  {
    helper.setUserData( component )
    .then(
      $A.getCallback( (response) => {
        var navMap = ['order-details',
                          'build-boat',
                          'review-container',
                          'finalize-container'];
        component.set('v.sessionId', response.sessionId );
        if( response.uiTheme !== 'Theme3' )
          component.set('v.inCommunity', false );
        component.set('v.currentAction', 0);
        component.set('v.navMap', navMap);
        component.find("orderDetails--Cmp").doInit();
      }),
      $A.getCallback( (err) => {
        LightningUtils.errorToast( err );
      })
    );
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
        LightningUtils.errorToast( err );
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
  }
})