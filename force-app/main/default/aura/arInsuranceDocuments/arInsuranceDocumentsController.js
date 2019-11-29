({
	doInit: function(component, event, helper) {
        component.set('v.loaded', false);
        helper.toggleSpinner(component, true);
        var projectId = component.get("v.recordId");
        helper.runAction(component, "c.retrieveERPDetails", {
            idProject: projectId
        }, function(response) {
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.erpData", results);
            component.set('v.canDelete', results.canDelete);
            var hasInsurance = results.hasInsurance == 'true' ? true : false;
            component.set("v.hasInsurance", hasInsurance);
            if(hasInsurance){
                var newUrl = '/apex/'+results.planPageName+'?id='+projectId;
	            component.set("v.pdfSRC", newUrl);
	            component.set("v.newPDFSRC", newUrl);
            }
            helper.toggleSpinner(component, false);
        });
        // This is to check for Old PDFs
        helper.runAction(component, "c.retrieveERPInsuranceDocuments", {
            idProject: component.get("v.recordId")
        }, function(response) {
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.oldPDFs", results);
            if(results.length > 0){
                component.set("v.newInsurancePDF", false);
                component.set("v.noInsurancePDF", false);
                component.set('v.selectedDocId', results[0].idDoc);
                component.set("v.pdfSRC", '/servlet/servlet.FileDownload?file='+results[0].idDoc);
            }else{
                component.set("v.newInsurancePDF", true);
                component.set("v.noInsurancePDF", true);
            }
            component.set('v.loaded', true);
            helper.toggleSpinner(component, false);
        });
    },

    loadPDF: function(component, event, helper) {
        helper.loadPDF(component, event, helper);
    },
    createNew: function(component, event, helper) {
        helper.createNew(component, event, helper);
    },
    cancelNew: function(component, event, helper) {
        helper.cancelNew(component, event, helper);
    },
    deleteDoc: function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var idDoc = selectedItem.dataset.dicid;
        var idErpDoc = selectedItem.dataset.iderpdoc;
        if( idDoc != component.get('v.selectedDocId') )
            return false;
        helper.confirmDelete( component )
        .then(
            $A.getCallback( function() {
                helper.toggleSpinner(component, true);
                helper.runAction(component, "c.deleteDocument", {
                    idProject: component.get("v.recordId"),
                    idErpDoc:idErpDoc,
                    idDoc: idDoc
                }, function(response) {
                    var state = response.getState();
                    if (state != "SUCCESS") {
                        var errors = response.getError();
                        if (errors) {
                            helper.toggleSpinner(component, false);
                            if (errors[0] && errors[0].message) {
                                helper.showToast(component, "Error In Save", "error", errors[0].message);
                            } else {
                                helper.showToast(component, "Error In Save", "error", "There was an error deleting document");
                            }
                            return;
                        }
                    }
                    var results = response.getReturnValue();
                    results = JSON.parse(results);
                    component.set("v.oldPDFs",results);
                    helper.toggleSpinner(component, false);
                    if(results.length == 0)
                    {
                        component.set("v.newInsurancePDF", true);
                        component.set("v.noInsurancePDF", true);
                    }
                    else
                    {
                        component.set("v.newInsurancePDF", false);
                        component.set("v.noInsurancePDF", false);
                        component.set('v.selectedDocId', results[0].idDoc);
                        component.set("v.pdfSRC", '/servlet/servlet.FileDownload?file='+results[0].idDoc);
                    }
                });
            }),
            $A.getCallback( function() {
                return false;
            })
        );

    },

    setPaymentDate: function( component, event, helper )
    {
        var modal = component.find('date-select-modal');
        $A.util.removeClass(modal, 'slds-hide');
    },

    cancelPaymentDate: function( component, event, helper )
    {
        var modal = component.find('date-select-modal');
        $A.util.addClass(modal, 'slds-hide');
    },

    saveNew: function(component, event, helper) {
        var modal = component.find('date-select-modal');
        $A.util.addClass(modal, 'slds-hide');
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.generateInsurancePDF", {
            idProject: component.get("v.recordId"),
            insuranceType: component.get("v.erpData").insuranceType,
            firstPaymentDate: component.get("v.firstPaymentDate"),
            language: component.get("v.language")
        }, function(response) {
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();
                if (errors) {
                    helper.toggleSpinner(component, false);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error In Save", "error", errors[0].message);
                    } else {
                        helper.showToast(component, "Error In Save", "error", "There was an error saving document");
                    }
                    return;
                }
            }
            var results = response.getReturnValue();
            results = JSON.parse(results);
            //var listPDF = component.get("v.oldPDFs");
			//listPDF.push(results);
            component.set("v.oldPDFs",results);
            //component.find("pdfIframe").set('v.src','/servlet/servlet.FileDownload?file='+results.idDoc);
            helper.cancelNew(component, event, helper);
            helper.toggleSpinner(component, false);
            component.set("v.newInsurancePDF", false);
            component.set("v.noInsurancePDF", false);
            component.set('v.selectedDocId', results[0].idDoc);
            component.set("v.pdfSRC", '/servlet/servlet.FileDownload?file='+results[0].idDoc);
        });
    }
})