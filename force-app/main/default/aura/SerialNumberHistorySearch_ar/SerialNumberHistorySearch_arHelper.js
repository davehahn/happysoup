({
    runAction: function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);
        // Register the callback function
        action.setCallback(this, callback);
        // Invoke the service
        $A.enqueueAction(action);
    },
    showToast: function(component, title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    toggleSpinner: function(component, value) {
        var spinner = component.find('spinner');
        window.setTimeout($A.getCallback(function() {
            if (value) {
                $A.util.removeClass(spinner, 'slds-hide');
            } else {
                $A.util.addClass(spinner, 'slds-hide');
            }
        }));
    },
    retrievehistory: function(component, event, helper) {
    	var idWhs = component.get("v.idWarehouse");
    	var idPrd = component.get("v.idProduct");
    	var idSrl = component.get("v.idSerial");
    	var startDate = component.get("v.today");
    	console.log(idPrd);
    	console.log(idSrl);
    	var idFlt = idSrl != null ? idSrl : (idPrd != null ? idPrd : (idWhs != null ? idWhs : ''))
    	if(idFlt == '') return;
    	if(idPrd == null && idSrl == null) return;
    	helper.toggleSpinner(component, true);
        helper.runAction(component, "c.retrieveHistoryDetails", {
            mapFilter: {
                idFilter: idFlt,
                idWarehouse: idWhs,
                idProduct: idPrd,
                idSerial: idSrl,
                startDate: startDate
            }
        }, function(response) {
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.listData", results);
            helper.toggleSpinner(component, false);
        });
    },
    clearProductSearch : function(component){
        var childCmp = component.find("searchProductComp");
        childCmp.clearSearch();
        component.set("v.idProduct",null);
    },
    clearSerialSearch : function(component){
        var childCmp = component.find("searchSerialComp");
        childCmp.clearSearch();
        component.set("v.idSerial",null);
    },
    clearFilters : function(component){
        component.set("v.idWarehouse","");
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