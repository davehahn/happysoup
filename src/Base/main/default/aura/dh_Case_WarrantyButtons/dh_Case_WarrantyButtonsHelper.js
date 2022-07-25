({
  headers: {
    1: "Select the Supplier",
    2: "Order Parts or Receive Credit"
  },

  setHeader: function (component) {
    var step = component.get("v.currentStep");
    component.set("v.header", this.headers[step]);
  },

  initButtons: function (component) {
    var action = component.get("c.fetchCase"),
      la;

    action.setParams({
      caseId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  toggleRecoverableModal: function (component) {
    var modal = component.find("recoverable-modal"),
      backDrop = component.find("back-drop");

    $A.util.toggleClass(modal, "slds-hide");
    $A.util.toggleClass(backDrop, "slds-backdrop_open");
  },

  fetchSuppliers: function (component) {
    var action = component.get("c.fetchAllSuppliers"),
      la;
    la = new LightningApex(this, action);
    return la.fire();
  },

  doStepOne: function (component) {
    var self = this,
      spinner = component.find("spinner");

    $A.util.toggleClass(spinner, "slds-hide");
    self.toggleRecoverableModal(component);
    self
      .createRecoverableERP(component)
      .then(
        $A.getCallback(function (result) {
          console.log(JSON.parse(JSON.stringify(result)));
          component.set("v.materials", result.materials);
          component.set("v.recoverableErpId", result.erpId);
          component.set("v.currentStep", 2);
          self.setHeader(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          $A.util.toggleClass(spinner, "slds-hide");
          self.toggleRecoverableModal(component);
        })
      );
  },

  doStepTwo: function (component) {
    var self = this,
      spinner = component.find("spinner");

    $A.util.toggleClass(spinner, "slds-hide");
    self.toggleRecoverableModal(component);
    self
      .createMaterials(component)
      .then(
        $A.getCallback(function (erpId) {
          LightningUtils.showToast("success", "Success", "Recoverable ERP created successfully");
          var action = $A.get("e.force:navigateToSObject");
          action
            .setParams({
              recordId: erpId
            })
            .fire();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
          self.toggleRecoverableModal(component);
        })
      )
      .finally(
        $A.getCallback(function () {
          $A.util.toggleClass(spinner, "slds-hide");
        })
      );
  },

  createRecoverableERP: function (component) {
    var action = component.get("c.createWarrantyRecoverableERP"),
      la;
    action.setParams({
      acctId: component.get("v.supplierId"),
      caseId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  deleteRecoverableERP: function (component) {
    var recoverableErpId = component.get("v.recoverableErpId"),
      action;
    if (recoverableErpId == null || recoverableErpId.length === 0)
      return new Promise(
        $A.getCallback(function (resolve) {
          resolve();
        })
      );

    action = component.get("c.deleteERP");
    action.setParams({
      erpId: recoverableErpId
    });
    return new LightningApex(this, action).fire();
  },

  createMaterials: function (component) {
    var action = component.get("c.createWarrantyRecoverableMaterials");
    action.setParams({
      JSONmaterials: JSON.stringify(component.get("v.materials"))
    });
    return new LightningApex(this, action).fire();
  }
});
