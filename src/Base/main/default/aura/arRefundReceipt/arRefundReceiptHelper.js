({
	getOptions : function(component) {
		var self = this,
				action = component.get('c.getOptions'),
				options;

		return new Promise( function( resolve, reject) {
			self.actionHandler.call(this, action).then(function(r) {
				component.set('v.options', r);
				resolve();
			})
		});
	},

	getReceiptAmount : function(component) {
		var self = this,
				cr = component.get('v.recordId'),
				action = component.get('c.getReceiptAmount');
		action.setParams({
			'crId': cr
		});
		return new Promise( function( resolve, reject) {
			self.actionHandler.call(this, action).then(function(r) {
				component.set('v.receiptData', r);
        component.set('v.refundAmount', r.AcctSeed__Balance__c);
				component.set('v.maxRefundAmount', r.AcctSeed__Balance__c);
				resolve();
			})
		});
	},

	validate : function(component, event, helper) {
		var amount = component.get('v.refundAmount'),
				cdType = component.get('v.cdType'),
				refundFrom = component.get('v.refundFrom'),
				receiptData = component.get('v.receiptData');
		var refundFromAmount = 0;
		if(refundFrom == 'Balance')
			refundFromAmount = receiptData.AcctSeed__Balance__c;
		else
			refundFromAmount = receiptData.AcctSeed__Amount__c;

		if (amount > 0 && amount <= refundFromAmount) {
			component.set('v.btnDisabled', false);
		}else if (amount > refundFromAmount ) {
			// helper.showToast(component, "Error", "error", "Refund must be less than "+refundFrom);
			component.set('v.btnDisabled', true);
		} else {
			component.set('v.btnDisabled', true);
		}
	},

	actionHandler: function( action )
  	{
    var self = this;
    return new Promise( function( resolve, reject ) {
      action.setCallback( self, function( response ) {
        var state = response.getState();
        if( state === 'SUCCESS' )
        {
        	console.log(response.getReturnValue());
          	resolve( response.getReturnValue() );
        }
        if( state === 'INCOMPLETE' )
        {
          reject( 'incomplete' );
        }
        if( state === 'ERROR' )
        {
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
  runAction : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);

        // Register the callback function
        action.setCallback(this, callback);

        // Invoke the service
        $A.enqueueAction(action);
	},
  showToast : function(component, title, type, message) {
    // var toast = component.find("toast");
    // toast.showToast(message, type);
    var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
              "title": title,
              "type": type,
              "message": message
        });
        toastEvent.fire();
	},
  toggleSpinner: function (component, value) {
      var spinner = component.find('spinner');
      
      window.setTimeout(
          $A.getCallback( function() {
              if (value) {
                  $A.util.removeClass(spinner, 'slds-hide');
              } else {
                  $A.util.addClass(spinner, 'slds-hide');
              }
          }));
  }
})