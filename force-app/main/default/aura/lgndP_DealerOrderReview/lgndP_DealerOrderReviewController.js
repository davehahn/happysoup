({
  doInit: function( component, event, helper )
  {
    helper.groupItems( component );
    component.find('dealerOrderLines--Cmp').doInit();
  },

  addToOrder : function(component, event, helper)
  {
    var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
    nav.setParams({"firedBy" : 2,
                "navigateTo": 1 });
    nav.fire();
  },

  cancelOrder: function( component, event, helper )
  {
    var cancelEvt = component.getEvent("cancelOrderEvent");
    cancelEvt.fire();
  },

  handleDetailsBtn: function( component )
  {
    var currentView = component.get('v.currentView');
    console.log( currentView );
    if( currentView === 'list' )
    {
      component.set('v.currentView', 'details');
      component.set('v.detailsBtnText', 'Less Details');
      component.find('dealerOrderLinesDetails--Cmp').doInit();
    }
    if( currentView === 'details' )
    {
      component.set('v.currentView', 'list');
      component.set('v.detailsBtnText', 'More Details');
      component.find('dealerOrderLines--Cmp').doInit();
    }
  },

  handleTableAction: function( component, event, helper )
  {
    var params = event.getParams(),
        groupId = params.id,
        action = params.action;
    // if( action == 'delete' )
    //   helper.deleteOrderRow( component, groupId );
    if( action == 'edit' )
      helper.editOrderRow( component, groupId );
    if( action == 'view' )
      helper.viewOrderRow( component, groupId );
  },

  handleCancelView: function( component, event, helper)
  {
    component.set('v.currentView', 'list');
    component.find('dealerOrderLines--Cmp').doInit();
  },

  draft : function(component, event, helper)
  {
    helper.navigateHome();
  },

  submit : function(component, event, helper)
  {
    helper.submitOrder( component )
    .then(
      $A.getCallback( function() {
        helper.navigateHome();
      }),
      $A.getCallback( function( err ){
        alert(err);
      })
    );
  }
})