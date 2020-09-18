/**
 * Created by dave on 2020-09-10.
 */

({
  initForFactoryStore: function( component )
  {
    component.set('v.applyFinished', true);
    this.initLines( component );
  },

  initForPartner: function( component )
  {
    const dealerOrderId = component.get('v.dealerOrder').Id;
    let empApi = component.get('v.inCommunity') ? component.find('cometD') : component.find('empApi');

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
          this.partnerProgramSuccess( component, eventReceived );
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

  partnerProgramSuccess: function( component, eventReceived )
  {
    console.log( 'partner Program apply success');
    component.set('v.applyFinished', true);
    this.initLines( component );
    const subscription = component.get('v.partnerProgramSubscription'),
          inCommunity = component.get('v.inCommunity');

    let empApi = inCommunity ? component.find('cometD') : component.find('empApi');

    empApi.unsubscribe( subscription, $A.getCallback( unsubscribed => {
      console.log('Unsubscribed from channel '+ unsubscribed.subscription);
      component.set('v.partnerProgramSubscription', null);
    }));

    console.log('PARTNER PROGRAM RESULT');
    console.log( JSON.parse( eventReceived.data.payload.Result__c ) );
    component.set('v.promotionMessage', JSON.parse( eventReceived.data.payload.Result__c ) );
  },

  initLines: function( component )
  {
    this.groupItems( component );
    component.find('dealerOrderLines--Cmp').doInit();
  },

  groupItems: function( component )
  {
    var dealerOrder = component.get('v.dealerOrder'),
        doLines = dealerOrder.Dealer_Order_Lines__r,
        lineItemsMap = {},
        total = 0,
        lineItems = [];

    for( var i=0; i < doLines.length; i++ )
    {
      if( lineItemsMap[ doLines[i].Order_Group_Id__c ] === undefined )
        lineItemsMap[ doLines[i].Order_Group_Id__c ] = [];
      lineItemsMap[ doLines[i].Order_Group_Id__c ].push( doLines[i] );
    }
    for( var key in lineItemsMap ) {
      if( lineItemsMap.hasOwnProperty(key) )
      {
        var data = {};
        data.quantity = lineItemsMap[key].length;
        data.eachPrice = lineItemsMap[key][0].Line_Total_Pre_Tax__c;
        data.totalPrice = data.eachPrice * data.quantity;
        data.productName = lineItemsMap[key][0].Product__r.Name;
        data.groupId = lineItemsMap[key][0].Order_Group_Id__c;
        lineItems.push( data );
        total += data.totalPrice;
      }
    }
    component.set('v.orderTotal', total);
  },

  editOrderRow: function( component, groupId )
  {
    var nav = $A.get('e.c:lgndP_DealerOrderNav_Event');
    nav.setParams({"firedBy" : 3,
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
    return new LightningApex( this, action ).fire();
  },

  toggleSpinner: function( component, message )
  {
    var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
    indEvt.setParams({message: message}).fire();
  }


});