({
	groupItems : function( component )
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

  submitOrder: function( component )
  {
    var self = this,
          action = component.get('c.submitDealerOrder');
    return new Promise( function( resolve, reject )
    {
      self.toggleSpinner(component, true);
      action.setParams({
        dealerOrderId: component.get('v.dealerOrder').Id
      });
      action.setCallback(self, function( response ) {
        var state = response.getState();
        if (state === "SUCCESS") {
          self.toggleSpinner(component, false);
          resolve();
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

  navigateHome: function()
  {
    var homeEvent = $A.get("e.force:navigateToObjectHome");
    homeEvent.setParams({
        "scope": "Dealer_Order__c"
    });
    homeEvent.fire();

  },

  toggleSpinner: function( component, busy )
  {
    var indEvt = $A.get('e.c:lgndP_BusyIndicator_Event');
    indEvt.setParams({isBusy: busy}).fire();
  }
})