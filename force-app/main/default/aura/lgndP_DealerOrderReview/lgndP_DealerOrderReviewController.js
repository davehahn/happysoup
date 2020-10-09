({
  doInit: function( component, event, helper )
  {
    console.log( 'DealerOrderReview.doInit');
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

  applyPartnerProgram: function( component, event, helper )
  {
    var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
    nav.setParams({"firedBy" : 2,
                "navigateTo": 3 });
    nav.fire();
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

})