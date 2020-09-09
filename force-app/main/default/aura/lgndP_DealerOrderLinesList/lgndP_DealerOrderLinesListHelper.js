({
  doInit: function( component )
  {
    let self = this;
    return new Promise( (resolve, reject ) => {
      self.fetchOrderDetails( component )
      .then(
        $A.getCallback( function( response ) {
          var result = JSON.parse( response );
          console.log(result);
          component.set('v.boats', result.boats );
          component.set('v.motors', result.motors );
          component.set('v.trailers', result.trailers );
          component.set('v.trollingMotors', result.trollingMotors );
          // helper.groupItems( component );
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

    self.toggleSpinner(component, true);

    action.setParams({
      groupId: groupId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS")
      {
        self.doInit( component )
        .then(
          $A.getCallback( function() {
            self.toggleSpinner(component, false);
          })
        );
//        self.removeOrderLine( component, groupId, itemType )
//        .then(
//          $A.getCallback( function() {
//            self.toggleSpinner(component, false);
//          })
//        )
      }
      else if (component.isValid() && state === "INCOMPLETE") {
      }
      else if (component.isValid() && state === "ERROR") {
        self.toggleSpinner(component, false);
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

    self.toggleSpinner( component, true );
    action.setParams({
      dealerOrderId: dealerOrder.Id
    });

    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve();
          self.toggleSpinner( component, false );
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

  toggleSpinner: function( component, busy )
  {
    var indicator = component.find('busy-indicator');
    if( busy )
      $A.util.removeClass( indicator, 'toggle' );
    else
      $A.util.addClass( indicator, 'toggle' );
  }

})