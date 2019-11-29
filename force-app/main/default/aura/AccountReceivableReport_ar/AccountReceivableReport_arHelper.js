({	
    runAction : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);
        // Register the callback function
        action.setCallback(this, callback);
        // Invoke the service
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
    nextPeriod: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.retrieveNextPeriod", {
            idPeriod: component.get("v.idPeriod")
        }, function(response) {
            helper.toggleSpinner(component, false);
            var results = response.getReturnValue();
            component.set("v.idPeriod",results);
        });        
    },
    previousPeriod: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.retrievePreviousPeriod", {
            idPeriod: component.get("v.idPeriod")
        }, function(response) {
            helper.toggleSpinner(component, false);
            var results = response.getReturnValue();
            component.set("v.idPeriod",results);
        });        
    },
    retrieveAccountDetails: function(component, event, helper) {
        if(component.get("v.donotLoad")) return;
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.retrieveAccountTxnDetails", {
            idPeriod: component.get("v.idPeriod")
        }, function(response) {
            helper.toggleSpinner(component, false);
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.transactionData", results);
        });        
    }
})