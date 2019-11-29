({
	doInit: function(component, event, helper)
  {
    var navMap = ['order-details',
                  'build-boat',
                  'review-container'];
    component.set('v.currentAction', 0);
    component.set('v.navMap', navMap);
    //hide all but statrting "order details form"
    $A.util.addClass( component.find('build-boat'), 'toggle');
    $A.util.addClass( component.find('review-container'), 'toggle');
    $A.util.addClass( component.find('busy-indicator'), 'toggle');
    component.find("orderDetails--Cmp").doInit();
  },

  handleOrderCancel: function( component, event, helper )
  {
    var indicator = component.find('busy-indicator');
    $A.util.removeClass( indicator, 'toggle' );
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
        indicator = component.find('busy-indicator');
    if( params.isBusy )
      $A.util.removeClass( indicator, 'toggle' );
    else
      $A.util.addClass( indicator, 'toggle' );
  }
})