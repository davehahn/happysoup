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

  submitOrder: function( component )
  {
    var self = this,
        dealerOrder = component.get('v.dealerOrder'),
        action = component.get('c.submitDealerOrder');

    self.toggleSpinner( component, 'Submitting Order' );
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });

    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve();
          self.toggleSpinner( component );
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

  toggleSpinner: function( component, message )
  {
    let evt = $A.get('e.c:lgndP_BusyIndicator_Event');
    evt.setParams({ message: message })
    .fire();
  }

})