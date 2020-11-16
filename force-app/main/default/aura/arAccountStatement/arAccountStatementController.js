({
    doInit: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        component.set('v.columns', [{
            label: 'Name',
            fieldName: 'Name',
            type: 'text'
        }, {
            label: 'ERP Order(s)',
            fieldName: 'billProject',
            type: 'text'
        }, {
            label: 'Balance',
            fieldName: 'billBalance',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'CAD'
            }
        }]);
        component.set('v.otherColumns', [{
            label: 'Name',
            fieldName: 'Name',
            type: 'text'
        }, {
            label: 'Balance',
            fieldName: 'AcctSeed__Balance__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'CAD'
            }
        }]);
        component.set('v.erpColumns', [{
            label: 'Name',
            fieldName: 'Name',
            type: 'text'
        }, {
            label: 'Grand Total',
            fieldName: 'grandTotal',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'CAD'
            }
        }, {
            label: 'Total Billed',
            fieldName: 'billTotal',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'CAD'
            }
        }, {
            label: 'Unbilled',
            fieldName: 'erpUnbilled',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'CAD'
            }
        }]);
        helper.runAction(component, "c.retrieveAccountTxnDetails", {
            idAccount: component.get("v.recordId")
        }, function(response) {
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.transactionData", results);
            component.set("v.refundAmount", results.totalARBalance);
            helper.toggleSpinner(component, false);
        });
        helper.runAction(component, "c.getOptions", {}, function(response) {
            component.set("v.options", response.getReturnValue());
        });
        helper.runAction(component, "c.getCDOptions", {}, function(response) {
            component.set("v.cdOptions", response.getReturnValue());
        });
    },
    rowSelected: function(component) {
        var billTable = component.find('billDataTable');
        var table;
        if (billTable != undefined && billTable.length > 1) {
            for (var i = billTable.length; i == 1; i--) billTable[i].destroy();
            table = billTable[1];
        } else table = billTable;
        // var table = component.find('billDataTable');
        if (table != undefined) {
            var selections = table.getSelectedRows();
            component.set('v.hasSelections', selections.length > 0);
        } else component.set('v.hasSelections', false);
        console.log(table);
    },
    validate: function(component, event, helper) {
        helper.validate(component, event, helper);
    },
    processRefund: function(component, event, helper) {
       helper.toggleSpinner(component, true);
       var transactionData = component.get("v.transactionData");
       var cdType = component.get('v.cdType'),
           refundAmount = component.get('v.refundAmount'),
           navEvt = $A.get("e.force:navigateToSObject");
       var refundFromAmount = transactionData.totalARBalance;
       if (refundAmount < refundFromAmount || isNaN(refundAmount)) {
           helper.showToast(component, "Error", "error", "Refund amount must be less than or equal to " + refundFromAmount);
           // component.set('v.btnDisabled', true);
           helper.toggleSpinner(component, false);
           return;
       }
       helper.closeRefundModal(component, event, helper);
       helper.processRefundStart(component, event, helper);
    },
    processRefund_Old: function(component, event, helper) {
        helper.toggleSpinner(component, true);
        var transactionData = component.get("v.transactionData");
        var cdType = component.get('v.cdType'),
            refundAmount = component.get('v.refundAmount'),
            navEvt = $A.get("e.force:navigateToSObject");
        var refundFromAmount = transactionData.totalARBalance;
        if (refundAmount < refundFromAmount || isNaN(refundAmount)) {
            helper.showToast(component, "Error", "error", "Refund amount must be less than or equal to " + refundFromAmount);
            // component.set('v.btnDisabled', true);
            helper.toggleSpinner(component, false);
            return;
        }
        helper.closeRefundModal(component, event, helper);
        helper.runAction(component, "c.handleRefund", {
            idAccount: component.get("v.recordId"),
            paymentMethod: cdType,
            refundAmount: refundAmount
        }, function(response) {
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();
                if (errors) {
                    helper.toggleSpinner(component, false);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error In Refund", "error", errors[0].message);
                    } else {
                        helper.showToast(component, "Error In Refund", "error", "There was an error creating refund");
                    }
                    return;
                }
            }
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.idBill", results.idBill);
            component.set("v.idPayable", results.idPayable);
            component.set("v.idDisbursement", results.idDisbursement);
            component.set("v.transactionData", JSON.parse(results.txnData));
            helper.openRefundSuccessModal(component, event, helper);
            // helper.showToast(component, "Refund", "success", "Refund processed successfully.");
            // $A.get('e.force:refreshView').fire();
            helper.toggleSpinner(component, false);
            // navEvt.setParams({
            //   "recordId": results,
            //   "slideDevName": "related"
            // });
            // navEvt.fire();
        });
    },
    gotoVFUnbilledPage: function(component, event, helper) {
        helper.closeModel(component, event, helper);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/gpProjectUnbilled_Report?idAccount=" + component.get("v.recordId")
        });
        urlEvent.fire();
    },
    createApplyCRSelect: function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        var arrVals = selectedMenuItemValue.split('__');
        var crId = arrVals[0];
        var applyType = arrVals[1];
        console.log(applyType);
        console.log(crId);
        helper.closeModel(component, event, helper);
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.applyCashReceipts", {
            idAccount: component.get("v.recordId"),
            idCR: crId,
            applyType: applyType
        }, function(response) {
            helper.toggleSpinner(component, false);
            var state = response.getState();
            if (state != "SUCCESS") {
                var errors = response.getError();
                if (errors) {
                    helper.openModelCR(component, event, helper);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error Applying Cash Receipt", "error", errors[0].message);
                    } else {
                        helper.showToast(component, "Error Applying Cash Receipt", "error", "There was an error applying balance.");
                    }
                }
                return;
            }
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.transactionData", results);
            helper.openModelCR(component, event, helper);
            helper.showToast(component, "Applied", "success", "Cash Receipt successfully applied.");
        });
    },
    receiveBillings: function(component, event, helper) {
        var typeSelect = component.find('receiptTypes').get('v.value');
        if (typeSelect == undefined || typeSelect == '') {
            helper.showToast(component, "Receipt Type.", "error", 'Please Select Receipt Type.');
            return;
        }
        // var table = component.find('billDataTable');
        var billTable = component.find('billDataTable');
        var table;
        if (billTable != undefined && billTable.length > 1) {
            table = billTable[1];
        } else table = billTable;
        var billIds = [];
        for (var bill of table.getSelectedRows()) billIds.push(bill.Id);
        helper.closeModel(component, event, helper);
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.receiveBilling", {
            idAccount: component.get("v.recordId"),
            idBills: billIds,
            paymentMethod: typeSelect
        }, function(response) {
            helper.toggleSpinner(component, false);
            var state = response.getState();
            // console.log(response);
            if (state != "SUCCESS") {
                var errors = response.getError();
                // console.log(errors);
                if (errors) {
                    helper.openModelBill(component, event, helper);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error Receiving Bills", "error", errors[0].message);
                    } else {
                        helper.showToast(component, "Error Receiving Bills", "error", "There was an error Receiving Bills.");
                    }
                }
                return;
            }
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.transactionData", results);
            helper.openModelBill(component, event, helper);
            helper.showToast(component, "Received", "success", "Billings were received successfully.");
        });
    },
    receiveBillings_Single: function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var idBill = selectedItem.dataset.id;
        helper.closeModel(component, event, helper);
        helper.toggleSpinner(component, true);
        helper.runAction(component, "c.receiveBilling", {
            idAccount: component.get("v.recordId"),
            idBill: idBill
        }, function(response) {
            helper.toggleSpinner(component, false);
            var state = response.getState();
            // console.log(response);
            if (state != "SUCCESS") {
                var errors = response.getError();
                // console.log(errors);
                if (errors) {
                    helper.openModelBill(component, event, helper);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, "Error Receiving Bill", "error", errors[0].message);
                    } else {
                        helper.showToast(component, "Error Receiving Bill", "error", "There was an error Receiving Bill.");
                    }
                }
                return;
            }
            var results = response.getReturnValue();
            results = JSON.parse(results);
            component.set("v.transactionData", results);
            helper.openModelBill(component, event, helper);
            helper.showToast(component, "Received", "success", "Billing received successfully.");
        });
    },
    closeToast: function(component, event, helper) {
        var toast = component.find("toast");
        window.setTimeout($A.getCallback(function() {
            $A.util.addClass(toast, 'slds-hide');
        }));
    },
    openRefundSuccessModal: function(component, event, helper) {
        helper.openRefundSuccessModal(component, event, helper);
    },
    closeRefundSuccessModal: function(component, event, helper) {
        helper.closeRefundSuccessModal(component, event, helper);
    },
    openRefundModal: function(component, event, helper) {
        helper.openRefundModal(component, event, helper);
    },
    closeRefundModal: function(component, event, helper) {
        helper.closeRefundModal(component, event, helper);
    },
    openModelBill: function(component, event, helper) {
        helper.openModelBill(component, event, helper);
    },
    openModelPayable: function(component, event, helper) {
        helper.openModelPayable(component, event, helper);
    },
    openModelCD: function(component, event, helper) {
        helper.openModelCD(component, event, helper);
    },
    openModelCR: function(component, event, helper) {
        helper.openModelCR(component, event, helper);
    },
    openModelERP: function(component, event, helper) {
        helper.openModelERP(component, event, helper);
    },
    closeModel: function(component, event, helper) {
        helper.closeModel(component, event, helper);
    }
})