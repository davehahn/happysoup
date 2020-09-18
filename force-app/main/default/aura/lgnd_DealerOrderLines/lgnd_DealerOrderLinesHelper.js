({
  getUserDetails: function( component )
  {
    var action = component.get( 'c.builderInit' );
    return new LightningApex( this, action ).fire();
  },


	fetchDealerOrder : function( component )
  {
    var recordId = component.get('v.recordId'),
        action = component.get('c.fetchDealerOrder');

    action.setParams({
      'recordId': recordId
    });

    return new LightningApex( this, action ).fire();

	},

  returnToLineView: function( component )
  {
    component.set('v.currentView', 'list');
    $A.get('e.force:refreshView').fire();
  },

  handleApplyPartnerProgram: function( component )
  {
    const inCommunity = component.get('v.inCommunity');
    const dealerOrderId = component.get('v.dealerOrder').Id;
    var indicator = component.find('busy-indicator');
    indicator.set('v.busyMessage', 'Applying Partner Program');
    component.set('v.applyingPartnerProgram', true);

    let self = this,
        empApi = inCommunity ? component.find('cometD') : component.find('empApi');

//    empApi.onError($A.getCallback(error => {
//        // Error can be any type of error (subscribe, unsubscribe...)
//        console.error('EMP API error: ', JSON.stringify(error));
//    }));
    empApi.subscribe(
      '/event/Partner_Program_Event__e',
      -1,
      $A.getCallback( eventReceived => {
        if( eventReceived.data.payload.Status__c === 'success' &&
            eventReceived.data.payload.DealerOrderId__c === dealerOrderId )
          self.partnerProgramSuccess( component, eventReceived );
      })
    )
    .then(
      $A.getCallback( subscription => {
        console.log('Subscription request sent to: ', subscription.channel);
        component.set('v.partnerProgramSubscription', subscription);
        self.applyPartnerProgram( component );
      })
    );
  },

  applyPartnerProgram: function( component )
  {
    console.log('applyPartnerProgram');
    const dealerOrder = component.get('v.dealerOrder');
    let action = component.get('c.applyPartnerProgram');
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });
    new LightningApex( this, action ).fire();
  },

  partnerProgramSuccess: function( component, message )
  {
    const subscription = component.get('v.partnerProgramSubscription'),
          inCommunity = component.get('v.inCommunity');
    let empApi = inCommunity ? component.find('cometD') : component.find('empApi'),
        indicator = component.find('busy-indicator')
    empApi.unsubscribe( subscription, $A.getCallback( unsubscribed => {
      console.log('Unsubscribed from channel '+ unsubscribed.subscription);
      component.set('v.partnerProgramSubscription', null);
    }));
    indicator.toggle();
    component.set('v.applyingPartnerProgram', false);
    console.log('PARTNER PROGRAM RESULT');
    console.log( JSON.parse( message.data.payload.Result__c ) );
    component.set('v.promotionMessage', JSON.parse( message.data.payload.Result__c ) );
    this.returnToLineView( component );
  }
})