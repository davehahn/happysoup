({
    runAction : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);
        
        // Register the callback function
        action.setCallback(this, callback);
        
        // Invoke the service
        $A.enqueueAction(action);
    },
    retrieveAccountReceipts: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        var idAccount = component.get('v.recordId');

        var billTable = component.find('billDataTable');
        if(billTable != undefined && billTable.length){
            for(var i = 0; i < billTable.length; i++)
                billTable[i].destroy();
        }
        this.runAction(component, "c.retrieveReceiptDetails", {
            idAccount: idAccount,
            idPeriod: component.get('v.idPeriod')
        }, function(response) {
            helper.toggleSpinner(component, false);
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.listTitle", "Cash Receipts");
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