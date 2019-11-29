({
    runAction : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);
        
        // Register the callback function
        action.setCallback(this, callback);
        
        // Invoke the service
        $A.enqueueAction(action);
    },
    retrieveAccountTransactions: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        var idAccount = component.get('v.idAccount');
        var idPeriod = component.get('v.idPeriod');
        var glAccountType = component.get('v.glAccountType');
        console.log(idAccount);
        console.log(idPeriod);
        console.log(glAccountType);
        this.runAction(component, "c.retrieveTxnDetailsByAccount", {
            idAccount: idAccount,
            idPeriod: idPeriod,
            strType: glAccountType
        }, function(response) {
            helper.toggleSpinner(component, false);
            var results = response.getReturnValue();
            results = JSON.parse(results);
            console.log(results);
            component.set("v.listTitle", glAccountType == 'arcontrol' ? "AR Control GL Transactions" : "Unapplied GL Transactions");
            component.set("v.listData", results);
        });
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