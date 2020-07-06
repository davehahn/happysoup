({
    doInit: function(component, event, helper) {
        helper.toggleSpinner(component, false);
        helper.runAction(component, "c.allRecordTypes", {}, function(response) {
            var results = response.getReturnValue();
            component.set("v.productTypes", JSON.parse(results));
        });
        helper.runAction(component, "c.allWarehouses", {}, function(response) {
            var results = response.getReturnValue();
            component.set("v.warehouses", JSON.parse(results));
            helper.retrieveProductDetails(component, event, null);
        });
    },
    sortTry: function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var datalabel = selectedItem.dataset.label;
        var tData = component.get("v.resultData");
        tData.sort(function(obj1, obj2) {
            return ((obj1[datalabel] === obj2[datalabel]) ? 0 : ((obj1[datalabel] > obj2[datalabel]) ? 1 : -1));
        });
        component.set("v.resultData",tData);
    },
    retrieveProductDetails: function(component, event, helper) {
        helper.clearProductSearch(component);
        component.set("v.page",1);
        helper.retrieveProductDetails(component, event, null);
    },
    retrieveProductDetailsPP: function(component, event, helper) {
        var page = component.get("v.page");
        component.set("v.page",page-1);
        helper.retrieveProductDetails(component, event, null);
    },
    retrieveProductDetailsNP: function(component, event, helper) {
        var page = component.get("v.page");
        component.set("v.page",page+1);
        helper.retrieveProductDetails(component, event, null);
    },
    handleFilterSelected: function( component, event, helper )
    {
        helper.clearFilters(component);
        var idFilter = event.getParam("filterId");
        var page = component.get("v.page");
        component.set("v.page",1);
        helper.retrieveProductDetails(component, event, idFilter);
    },
    handleSupplierSelected: function( component, event, helper )
    {
        console.log('I am here');
        helper.clearFilters(component);
        helper.clearProductSearch(component);
        var accountId = event.getParam("accountId");
        component.set("v.idSupplier",accountId);
        var page = component.get("v.page");
        component.set("v.page",1);
        //helper.retrieveProductDetails(component, event, null);
    },
    clearAccountSelection: function( component, event, helper )
    {
        console.log('I am clear');
        component.set("v.idSupplier","");
    }
})