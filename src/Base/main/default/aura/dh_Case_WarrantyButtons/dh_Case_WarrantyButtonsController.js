({
  doInit: function (component, event, helper) {
    helper.initButtons(component).then(
      $A.getCallback(function (caseRecord) {
        console.log(caseRecord);
        component.set("v.hasRecoverable", caseRecord.Recoverable_ERP__c && caseRecord.Recoverable_ERP__c !== "");
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  createRecoverable: function (component, event, helper) {
    var spinner = component.find("spinner");
    $A.util.toggleClass(spinner, "slds-hide");
    helper.fetchSuppliers(component).then(
      $A.getCallback(function (result) {
        helper.setHeader(component);
        $A.util.toggleClass(spinner, "slds-hide");
        component.set("v.suppliers", result);
        helper.toggleRecoverableModal(component);
      }),
      $A.getCallback(function (err) {
        $A.util.toggleClass(spinner, "slds-hide");
        LightningUtils.errorToast(err);
      })
    );
  },

  cancelRecoverable: function (component, event, helper) {
    var spinner = component.find("spinner");
    $A.util.toggleClass(spinner, "slds-hide");
    helper.toggleRecoverableModal(component);

    helper
      .deleteRecoverableERP(component)
      .then(
        $A.getCallback(function (result) {
          component.set("v.supplierId", null);
          component.set("v.supplierQuery", "");
          component.set("v.currentStep", 1);
          component.set("v.recoverableErpId", "");
          component.set("v.materials", []);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          $A.util.toggleClass(spinner, "slds-hide");
        })
      );
  },

  handleContinue: function (component, event, helper) {
    var step = component.get("v.currentStep");
    if (step === 1) {
      helper.doStepOne(component);
    }
    if (step == 2) {
      helper.doStepTwo(component);
    }
  }
});
