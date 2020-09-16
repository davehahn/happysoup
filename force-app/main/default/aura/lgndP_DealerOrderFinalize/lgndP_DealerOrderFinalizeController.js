/**
 * Created by dave on 2020-09-10.
 */

({
  doInit: function( component, event, helper )
  {
    console.log('finalize doInit');
    component.set('v.applyFinished', false);
    const inCommunity = component.get('v.inCommunity'),
          dealerOrderId = component.get('v.dealerOrder').Id;

    let empApi = inCommunity ? component.find('cometD') : component.find('empApi');

//    empApi.onError($A.getCallback(error => {
//        // Error can be any type of error (subscribe, unsubscribe...)
//        console.error('EMP API error: ', JSON.stringify(error));
//    }));
    empApi.subscribe(
      '/event/Partner_Program_Event__e',
      -1,
      $A.getCallback( eventReceived => {
        console.log('Received event ');
        console.log( eventReceived );
        if( eventReceived.data.payload.Status__c === 'success' &&
            eventReceived.data.payload.DealerOrderId__c === dealerOrderId )
          helper.partnerProgramSuccess( component, eventReceived );
      })
    )
    .then(
      $A.getCallback( subscription => {
        console.log('Subscription request sent to: ', subscription.channel);
        component.set('v.partnerProgramSubscription', subscription);
        helper.applyPartnerProgram( component );
      })
    );

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