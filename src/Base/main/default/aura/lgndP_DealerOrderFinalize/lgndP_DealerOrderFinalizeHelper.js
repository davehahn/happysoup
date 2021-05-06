/**
 * Created by dave on 2020-09-10.
 */

({
  init: function( component )
  {
    const startMonthDay = component.get('v.bookingOrderStartMonthDay').split('/');
    const startDate = new Date( new Date().getFullYear(), startMonthDay[0] - 1, startMonthDay[1], 0, 0, 0 );
    let dealerOrder = component.get('v.dealerOrder');
    let canSubmit = true;
    if( dealerOrder.Is_Booking_Order__c	)
    {
      console.log( Date.now() );
      console.log( startDate.getTime() );
      canSubmit = Date.now() > startDate.getTime();
    }
    component.set('v.canSubmit', canSubmit	);
    this.initLines( component );
  },

  savePartnerProgramAndSubmit: function( component )
  {
    let self = this;
    const dealerOrderId = component.get('v.dealerOrder').Id;
    const inCommunity = component.get('v.inCommunity');
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
        {
          console.log( 'partner Program apply success');
          self.unsubscribeToEvent( component );
          self.changeSpinnerMessage( component, 'Submitting Order' );
          self.submitOrder( component );
        }
      })
    )
    .then(
      $A.getCallback( subscription => {
        console.log('Subscription request sent to: ', subscription.channel);
        component.set('v.partnerProgramSubscription', subscription);
        this.applyPartnerProgram( component );
      })
    );
  },

  unsubscribeToEvent: function( component )
  {
    const inCommunity = component.get('v.inCommunity');
    let empApi = inCommunity ? component.find('cometD') : component.find('empApi');
    let subscription = component.get('v.partnerProgramSubscription');
    empApi.unsubscribe( subscription, $A.getCallback( unsubscribed => {
      console.log('Unsubscribed from channel '+ unsubscribed.subscription);
      component.set('v.partnerProgramSubscription', null);
    }));
  },

  applyPartnerProgram: function( component )
  {
    console.log('APPLY PARTNER ORDER');
    const dealerOrder = component.get('v.dealerOrder');
    let action = component.get('c.applyPartnerProgram');
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });
    new LightningApex( this, action ).fire();
  },

  initLines: function( component )
  {
    component.find('dealerOrderLines--Cmp').doInit();
  },

  editOrderRow: function( component, groupId )
  {
    var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
    nav.setParams({"firedBy" : 2,
                "navigateTo": 1,
                "groupId": groupId });
    nav.fire();
  },

  viewOrderRow: function( component, groupId )
  {
    component.set('v.currentView', 'view');
    component.find('dealerOrderLineView--Cmp').doInit( groupId );
  },

  navigateHome: function()
  {
    var homeEvent = $A.get("e.force:navigateToObjectHome");
    homeEvent.setParams({
        "scope": "Dealer_Order__c"
    });
    homeEvent.fire();
  },

  submitOrder: function( component )
  {
    var self = this,
        action = component.get('c.submitDealerOrder');

    action.setParams({
      dealerOrderId: component.get('v.dealerOrder').Id
    });

    new LightningApex( this, action )
    .fire()
    .then(
      $A.getCallback( function() {
        self.navigateHome();
      }),
      $A.getCallback( function( err ){
        LightningUtils.errorToast(err);
      })
    )
    .finally( $A.getCallback( () => {
      self.toggleSpinner(component, '');
    }));
  },

  toggleSpinner: function( component, message )
  {
    var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
    indEvt.setParams({message: message}).fire();
  },

  changeSpinnerMessage: function( component, message )
  {
    var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
    indEvt.setParams(
      {
        message: message,
        messageOnly: true
      }
    ).fire();
  },

  confirm: function( component, confirmParams )
  {
    var confirmCmp = component.find('lgnd-confirm');

    return new Promise( function( resolve, reject ) {
      component.addEventHandler('c:lgnd_Confirm_Response_Event', function( auraEvent ) {
        auraEvent.getParam('theResponse')  ? resolve() : reject();
      });
      confirmCmp.showConfirm( confirmParams );
    });
  },


});