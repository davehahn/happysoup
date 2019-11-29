({
	runAction : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);

        // Register the callback function
        action.setCallback(this, callback);

        // Invoke the service
        $A.enqueueAction(action);
 	},
    loadPDF: function(component, event, helper) {
        //helper.toggleSpinner(component, true);
        var selectedItem = event.currentTarget;
        var idDoc = selectedItem.dataset.dicid;
        var idErpDoc = selectedItem.dataset.iderpdoc;
        console.log(idErpDoc);
        console.log(idDoc);
        component.set('v.selectedDocId', idDoc);
        component.set("v.pdfSRC", '/servlet/servlet.FileDownload?file='+idDoc);
        /*var mainTable = component.find('data-main-table');
        console.log(mainTable);
        $A.util.removeClass(mainTable, 'highlighted');
        var cmpTarget = selectedItem.parentNode.parentNode;
        $A.util.addClass(cmpTarget, 'highlighted');*/

        //helper.toggleSpinner(component, false);
    },
    createNew: function(component, event, helper) {
        component.set("v.newInsurancePDF", true);
        component.set("v.pdfSRC", component.get("v.newPDFSRC"));
    },
    cancelNew: function(component, event, helper) {
        var oldPDFs = component.get("v.oldPDFs");
        if(oldPDFs.length > 0)
        {
            component.set("v.newInsurancePDF", false);
            component.set("v.pdfSRC", '/servlet/servlet.FileDownload?file='+oldPDFs[0].idDoc);
            //component.set("v.pdfSRC", component.get("v.newPDFSRC"));
        }
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
    },
    confirmDelete: function( component ) {
        var confirmParams = {
                title: "Delete This Document?",
                message: "This is permanent and can not be undone!",
                state: 'error'
            },
            confirmCmp = component.find('lgnd-confirm');
        return new Promise( function( resolve, reject ) {
          component.addEventHandler('c:lgnd_Confirm_Response_Event', function( auraEvent ) {
            auraEvent.getParam('theResponse')  ? resolve() : reject();
          });
          confirmCmp.showConfirm( confirmParams );
        });
    }
})