({
	getInitValues: function( component )
  {
    var action = component.get("c.getInitNewOrder"), la;
    la = new LightningApex( this, action );
    return la.fire();
  },

  fetchFinanceCompanies: function( component )
  {
    var dealerOrder = component.get('v.dealerOrder'),
        action = component.get('c.fetchFinanceCompanys'),
        la;

    action.setParams({
      accountId: dealerOrder.Account__c
    });

    la = new LightningApex( this, action );
    return la.fire();
  },

  checkForPartnerBookingOrder: function( component, programYear )
  {
    const accountId = component.get('v.dealerOrder').Account__c;
    let action = component.get('c.findBookingOrder');

    action.setParams({
      programYear: programYear,
      accountId: accountId
    });

    return new LightningApex( this, action ).fire();
  },

  saveOrder: function( component )
  {
    var self = this;
    self.toggleSpinner( true );
    self.doOrderSave( component )
    .then(
      $A.getCallback( function( result ) {
        component.set( 'v.dealerOrder', result );
        var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
        nav.setParams({"firedBy" : 0,
                    "navigateTo": 1 })
        .fire();
      }),
      $A.getCallback( function( err ) {
        try{
          LightningUtilis.errorToast( err );
        }catch(e){

        }
      })
    )
    .finally( $A.getCallback( function() {
      self.toggleSpinner( false );
    }));
  },


  doOrderSave: function( component )
  {
    var dealerOrder = component.get('v.dealerOrder'),
        action = component.get("c.saveDealerOrder"),
        la;

    /* remove the Dealer_Order_Lines just from the object we are
       serializing.  Apex deserialize method chokes if they are included */
    delete dealerOrder.Dealer_Order_Lines__r;

    action.setParams({
      'dealerOrderJSON': JSON.stringify( dealerOrder )
    });

    la = new LightningApex( this, action );
    return la.fire();
  },

  toggleSpinner: function( isBusy, message )
  {
    var busy = $A.get('e.c:lgndP_BusyIndicator_Event');
    busy.setParams({isBusy: isBusy, message: message}).fire();
  }
})