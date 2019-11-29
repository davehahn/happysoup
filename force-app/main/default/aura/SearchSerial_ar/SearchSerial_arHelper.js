({
	runAction : function(component, actionName, params, callback) {
		var action = component.get(actionName);
		action.setParams(params);
		action.setCallback(this, callback);
		$A.enqueueAction(action);
 	},
	showToast : function(component, title, type, message) {
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
	},
	toggle : function(element, action) {
		if (action == 'open') {
			$A.util.removeClass(element, 'slds-is-closed');
			$A.util.addClass(element, 'slds-is-open');
		} else if (action == 'close') {
			$A.util.removeClass(element, 'slds-is-open');
			$A.util.addClass(element, 'slds-is-closed');
		}
	}

})