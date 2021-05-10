/**
 * Created by dave on 2020-09-10.
 */

({
  doInit: function( component, event, helper )
  {
    helper.init( component );
  },

  cancelOrder: function( component, event, helper )
  {
    var cancelEvt = component.getEvent("cancelOrderEvent");
    cancelEvt.fire();
  },

  addToOrder: function( component, event, helper )
  {
     var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
     nav.setParams({"firedBy" : 2,
                 "navigateTo": 1 });
     nav.fire();
  },

  saveDraft: function( component, event, helper )
  {
    helper.navigateHome();
  },

  handleCheckPartnerProgram: function( component, event, helper )
  {
    helper.toggleSpinner( component, 'Calculating Applicable Discounts under the Partner Program');
    helper.checkPartnerProgram( component );
  },

  submit: function( component, event, helper )
  {
    const confirmParams = {
      title: "Submit this order?",
      message: "Once this order is submitted it will be locked from further editing!"
    };
    const isInternal = component.get('v.dealerOrder').Account__r.Is_Internal__c;
    const spinnerMessage = isInternal ?
      'Submitting Order' :
      'Calculating and Applying Applicable Discounts under the Partner Program';

    helper.confirm( component, confirmParams )
    .then(
      $A.getCallback( function() {
        helper.toggleSpinner( component, spinnerMessage );
        if( isInternal)
        {
          helper.submitOrder( component );
        }
        else
        {
          helper.savePartnerProgramAndSubmit( component );
        }
      }),
      $A.getCallback( function() {
        return Promise.reject();
      })
    );
  },

  handleTableAction: function( component, event, helper )
  {
    var params = event.getParams(),
        groupId = params.id,
        action = params.action;
    if( action == 'edit' )
      helper.editOrderRow( component, groupId );
    if( action == 'view' )
      helper.viewOrderRow( component, groupId );
  },

  handleCancelView: function( component, event, helper )
  {

  }
});