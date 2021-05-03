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
    retrieveProductDetails: function(component, event, idProduct) {
        if(component.get("v.donotLoad")) return;
        var checkCmp = component.find("showAllCheckbox");
        this.toggleSpinner(component, true);
        var page = component.get("v.page");
        this.runAction(component, "c.retrieveProductDetail", {
            idRecordType: component.get("v.idRecordType"),
            pageNumber: component.get("v.page"),
            orderBy: component.get("v.orderBy"),
            orderDirection: component.get("v.orderDirection"),
            idWarehouse: component.get("v.idWarehouse"),
            idProduct: idProduct,
            showAll:checkCmp.get("v.value"),
            idSupAccount:component.get("v.idSupplier")
        }, function(response) {
            this.toggleSpinner(component, false);
            var results = response.getReturnValue();
            results = JSON.parse(results);
            console.log(results);
            component.set("v.page", results.pageNumber);
            component.set("v.total", results.totalRecords);
            component.set("v.pages", Math.ceil(results.totalRecords / 50));
            component.set("v.resultData", results.listTxnData);
        });
    },
    clearProductSearch : function(component){
        var childCmp = component.find("searchProductComp");
        childCmp.clearSearch();
    },
    clearFilters : function(component){
        component.set("v.donotLoad",true);
        component.set("v.idRecordType","");
        component.set("v.idSupplier","");
        component.set("v.idWarehouse","");
        component.set("v.donotLoad",false);
    }
})