/**
 * Created by dave on 2020-09-10.
 */

({
  doInit: function( component, event, helper )
  {
    console.log('finalize doInit');

    const isFactoryStore = component.get('v.dealerOrder').Account__r.Is_Internal__c;

    if( isFactoryStore )
      helper.initForFactoryStore( component );
    else
    {
      component.set('v.applyFinished', false);
      helper.initForPartner( component );
    }
  },

  cancelOrder: function( component, event, helper )
  {
    var cancelEvt = component.getEvent("cancelOrderEvent");
    cancelEvt.fire();
  },

  addToOrder: function( component, event, helper )
  {
     var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
     nav.setParams({"firedBy" : 3,
                 "navigateTo": 1 });
     nav.fire();
  },

  saveDraft: function( component, event, helper )
  {
    helper.navigateHome();
  },

  submit: function( component, event, helper )
  {
    helper.toggleSpinner(component, 'Submitting Order ');
    helper.submitOrder( component )
    .then(
      $A.getCallback( function() {
        helper.navigateHome();
      }),
      $A.getCallback( function( err ){
        LightningUtils.errorToast(err);
      })
    )
    .finally( $A.getCallback( () => {
      helper.toggleSpinner(component, '');
    }));
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

  handleCancelView: function( component, event, helper )
  {

  }
});