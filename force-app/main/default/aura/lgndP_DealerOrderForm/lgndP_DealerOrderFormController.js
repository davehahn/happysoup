({
	doInit : function(component, event, helper)
  {
    helper.getInitValues( component ).
    then(
      $A.getCallback( function( result ) {
        console.log( JSON.parse( JSON.stringify( result ) ) );
        component.set('v.dealerOrder', result.dealerOrder );
        component.set('v.programYearOptions', result.programYearOptions );
        component.set('v.financeCompanyOptions', result.financeCompanyOptions );
        component.set('v.paymentMethodOptions', result.paymentMethodOptions );
        component.set('v.fromInternal', result.fromInternal);
        component.set('v.isFactoryStore', result.isFactoryStore );
        component.set('v.accountOptions', result.accountOptions );
        component.set('v.legendAccounts', result.legendAccounts );
        component.set('v.lockBookingOrderToggle', true );
//        if( result.fromInternal )
//          component.set('v.lockBookingOrderToggle', false);
//        if( !result.fromInternal &&
//            result.dealerOrder.Is_Booking_Order__c )
//        {
//          component.set('v.lockBookingOrderToggle', false);
//        }
      }),
      $A.getCallback( function( err ) {
        LightningUtilis.errorToast( err );
      })
    )
    .finally( $A.getCallback( () => {
      helper.toggleSpinner( false );
    }))
	},

  handleAccountChange: function( component, event, helper )
  {
    var accountId = component.get('v.dealerOrder.Account__c'),
        dealerOrder = component.get('v.dealerOrder'),
        legendAccounts = component.get('v.legendAccounts');

    if( legendAccounts.indexOf(accountId) < 0 )
    {
      dealerOrder.Is_Legend_Transfer__c = false;
      helper.toggleSpinner( true );
      helper.fetchFinanceCompanies( component )
      .then(
        $A.getCallback( function(result) {
          component.set('v.financeCompanyOptions', result );
          component.set('v.dealerOrder', dealerOrder);
        }),
        $A.getCallback( function( err ) {
          LightningUtils.errorToast( err );
        })
      )
      .finally( $A.getCallback( function() {
        helper.toggleSpinner( false );
      }))
    }
    else
    {
      dealerOrder.Is_Legend_Transfer__c = true;
      component.set('v.dealerOrder', dealerOrder);
      component.set('v.financeCompanyOptions', [] );
    }
  },

  handlePaymentMethodChange: function( component, event, helper )
  {
    var dealerOrder = component.get('v.dealerOrder');
    if( dealerOrder.Payment_Method__c === 'Cash' )
    {
      dealerOrder.Financing_Company__c = null;
      component.set('v.dealerOrder', dealerOrder );
    }

  },

  orderComplete: function( component, event, helper )
  {
    var requiredFields = component.find('requiredField');
    if( requiredFields.length === undefined )
      requiredFields = [requiredFields];
    if( requiredFields === null || requiredFields == undefined )
      requiredFields = [];
    var allValid = requiredFields.reduce(function (validSoFar, inputCmp) {
        inputCmp.showHelpMessageIfInvalid();
        return validSoFar && inputCmp.get('v.validity').valid;
    }, true);
    if (allValid) {
        helper.saveOrder( component );
    } else {
        console.log('Please update the invalid form entries and try again.');
    }
  },

  cancelOrder: function( component, event, helper )
  {
    var cancelEvt = component.getEvent("cancelOrderEvent");
    cancelEvt.fire();
  }
})