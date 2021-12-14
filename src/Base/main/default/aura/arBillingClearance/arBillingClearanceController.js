({
	doInit: function(component, event, helper) {
        helper.toggleSpinner(component, false);
        component.set('v.columns', [
          {label: 'Name', fieldName: 'Name', type: 'text'},
          {label: 'ERP Order', fieldName: 'billProject', type: 'text'},
          {label: 'Customer Name', fieldName: 'billCustomer', type: 'text'},
          {label: 'Balance', fieldName: 'billBalance', type: 'currency', typeAttributes: { currencyCode: 'CAD'}}
        ]);
    },
    searchInputKeyUp: function(component, event, helper) {
        if (event.getParams().keyCode == 13) {
            component.set("v.searchText", component.find("searchInput").get("v.value"));
        }        
    },
    openModal: function( component, event, helper )
    {
        component.set('v.hasSelections', true );
        var selectedItem = event.currentTarget;
        var idBill = selectedItem.dataset.idbill;
        var amount = selectedItem.dataset.amount;
        component.set("v.selectedBillingId", idBill);
        component.set("v.clearingAmount", amount);
    },
    openAttachmentModal: function( component, event, helper )
    {
        component.set('v.hasAttachment', true );
        
    },
    validate: function(component, event, helper) {
        helper.validate(component, event, helper);
    },
    onSearch: function(component, event, helper) {
        helper.onSearch(component, event, helper);
    },
    processClearance: function(component, event, helper) {
        var idBill = component.get("v.selectedBillingId"),
            navEvt = $A.get("e.force:navigateToSObject");

        if (!idBill) {
            helper.showToast(component, "Billing", "error", "Please select a billing to proceed.");
            return;
        }
        helper.toggleSpinner(component, true);

        helper.runAction(component, "c.createClearance", {
            idBill: idBill,
            pClearAmount: component.get("v.clearingAmount"),
            apReference: component.get("v.clearingReference")
        }, function(response) {
            helper.toggleSpinner(component, false);
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error Clearing Bill", "error", errors[0].message);
                    }else {
                        helper.showToast(component, "Error Clearing Bill", "error", "There was an error Clearing Bill.");
                    }
                }
                return;
            }
            var results = response.getReturnValue();
            if(results != null || results.length != 0 ){
                component.set('v.hasAttachment', true );
                component.set('v.recordId', results );
            }
            helper.closeModal(component, event, helper);
            helper.onSearch(component, event, helper);
            
            // navEvt.setParams({
            //   "recordId": results,
            //   "slideDevName": "related"
            // });
            // navEvt.fire();
        });
    },
    closeModal: function(component, event, helper) {
        helper.closeModal(component, event, helper);  
    },
     closeModalAttachment: function(component, event, helper) {
        helper.closeModalAttachment(component, event, helper);  
    },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        // Get the file name
        uploadedFiles.forEach(file => console.log(file.name));
    }
})