({
  doInit: function( component )
  {
    let self = this;
    return new Promise( (resolve, reject ) => {
      self.fetchOrderDetails( component )
      .then(
        $A.getCallback( function( response ) {
          var result = JSON.parse( response );
          console.log( JSON.parse( JSON.stringify(result)));
          component.set('v.boats', result.boats );
          component.set('v.motors', result.motors );
          component.set('v.trailers', result.trailers );
          component.set('v.trollingMotors', result.trollingMotors );
          self.setIsEditable( component );
          resolve();
        }),
        $A.getCallback( function( err ) {
          console.log( err );
          reject( err );
        })
      );
    })
  },

  fetchOrderDetails: function( component )
  {
    var self = this,
        dealerOrderId = component.get('v.dealerOrder').Id,
        action = component.get('c.fetchUniqueOrderDetails');

    action.setParams({
      recordId: dealerOrderId
    });

    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve( response.getReturnValue() );
        }
        else if (component.isValid() && state === "INCOMPLETE") {
          reject( 'incomplete' );
        }
        else if (component.isValid() && state === "ERROR") {
          var errors = response.getError();
          if (errors) {
              if (errors[0] && errors[0].message) {
                  reject("Error message: " +
                           errors[0].message);
              }
          } else {
              reject("Unknown error");
          }
        }
      });

      $A.enqueueAction( action );
    });
  },

  setIsEditable: function( component )
  {
    var answer = false,
        dealerOrder = component.get('v.dealerOrder'),
        userType = component.get('v.userType');

    if( userType === 'Standard' && !dealerOrder.isLocked__c )
      answer = true;
    else
    {
      if( dealerOrder.Stage__c === 'Draft' )
        answer = true;
    }
    component.set('v.isEditable', answer );
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

  deleteOrderRow: function( component, groupId, itemType )
  {
    console.log( itemType );
    var self = this,
        action = component.get('c.deleteOrderGroup');

    self.toggleSpinner(component, 'Deleting Line Item');

    action.setParams({
      groupId: groupId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS")
      {
        self.toggleSpinner(component);
        $A.get('e.force:refreshView').fire();
        var toast = $A.get('e.force:showToast');
        toast.setParams({
          message: 'Your order was submitted successfully!',
          type: 'success'
        })
        .fire();
      }
      else if (component.isValid() && state === "INCOMPLETE") {
      }
      else if (component.isValid() && state === "ERROR") {
        self.toggleSpinner(component);
        var errors = response.getError();
        if (errors) {
            if (errors[0] && errors[0].message) {
                alert("Error message: " +
                         errors[0].message);
            }
        } else {
            alert("Unknown error");
        }
      }
    });
    $A.enqueueAction( action );
  },

  removeOrderLine: function( component, groupId, itemType )
  {

    return new Promise( function( resolve, reject) {
      var v = 'v.'+itemType,
          lineItems = component.get( v ),
          index;
      for( var i=0; i<lineItems.length; i++ )
      {
        if( lineItems[i].orderGroupId === groupId )
        {
          index = i;
          break;
        }
      }
      if( index !== null )
        lineItems.splice(index, 1);
      component.set(v, lineItems);
      resolve();
    });
  },

  applyPartnerProgramAndSubmit: function(component )
  {
    let self = this;
    const dealerOrderId = component.get('v.dealerOrder').Id;
    const inCommunity = component.get('v.inCommunity');
    let empApi = inCommunity ? component.find('cometD') : component.find('empApi');

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
          console.log( JSON.parse( eventReceived.data.payload.Result__c ) );
          component.set('v.promotionMessage', JSON.parse( eventReceived.data.payload.Result__c ) );
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

  submitOrder: function( component )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder'),
        action = component.get('c.submitDealerOrder');

    action.setParams({
      dealerOrderId: dealerOrder.Id
    });

    new LightningApex( self, action )
    .fire()
    .then(
      $A.getCallback( function(result) {
        self.toggleSpinner( component );
        $A.get('e.force:refreshView').fire();
        var toast = $A.get('e.force:showToast');
        toast.setParams({
          message: 'Your order was submitted successfully!',
          type: 'success'
        })
        .fire();
      }),
      $A.getCallback( function( err ) {
        if( err !== undefined )
        {
          console.log( err );
          LightningUtils.errorToast( err );
        }
      })
    );
  },

  toggleSpinner: function( component, message )
  {
    let evt = $A.get('e.c:lgndP_BusyIndicator_Event');
    evt.setParams({ message: message })
    .fire();
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
  }

})