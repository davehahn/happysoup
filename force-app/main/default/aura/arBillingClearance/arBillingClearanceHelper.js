({
    closeModal: function(component, event, helper) {
        component.set("v.hasSelections", false); 
        component.set("v.selectedBillingId", "");
        component.set("v.clearingReference", "");
        component.set("v.clearingAmount", 0);
    },
    onSearch: function(component, event, helper) {
        var searchText = component.get("v.searchText");
        
        if (!searchText) {
            helper.showToast(component, "Search Billing", "error", "Please enter a valid text to search.");
            return;
        }
        helper.toggleSpinner(component, true);

        helper.runAction(component, "c.retrieveBillings", {
            searchParam: searchText,
            searchType: 'Recoverable'
        }, function(response) {
            var results = response.getReturnValue();
            results = JSON.parse(results);
            console.log(results);
            component.set("v.listERPBills", results);
            helper.toggleSpinner(component, false);
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
    validate : function(component, event, helper) {
        var amount = component.get('v.clearingAmount'),
            cRef = component.get('v.clearingReference');

        if (amount == 0 || amount == undefined || amount == '' || isNaN(amount) || cRef == '' || cRef == undefined) {
            component.set('v.btnDisabled', true);
        }else {
            component.set('v.btnDisabled', false);
        }
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
    }
})