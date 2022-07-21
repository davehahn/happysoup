({
  findPermissions: function (component) {
    var action = component.get("c.fetchCasePartsPermissions"),
      la;

    action.setParams({
      caseId: component.get("v.recordId")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  fetchCaseParts: function (component) {
    var la,
      action = component.get("c.fetchCaseParts");

    action.setParams({
      caseId: component.get("v.recordId")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  deleteRecordRow: function (component, recordId) {
    var self = this,
      confirmParams = {
        title: "Delete This part?",
        message: "This permanent and can not be undone!"
      };
    self.confirm(component, confirmParams).then(
      $A.getCallback(function () {
        self.doDelete(component, recordId);
      }),
      $A.getCallback(function () {
        return false;
      })
    );
  },

  doDelete: function (component, recordId) {
    var self = this,
      action = component.get("c.deleteCasePart"),
      spinner = component.find("spinner"),
      la;

    action.setParams({
      recordId: recordId
    });

    $A.util.toggleClass(spinner, "slds-hide");
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function () {
        $A.get("e.force:refreshView").fire();
        self.showToast("success", "Success", "Record was deleted");
        $A.util.toggleClass(spinner, "slds-hide");
      }),
      $A.getCallback(function (err) {
        this.showToast("error", "There was an error", err);
      })
    );
  },

  editRow: function (recordId) {
    var editRecordEvent = $A.get("e.force:editRecord");
    editRecordEvent
      .setParams({
        recordId: recordId
      })
      .fire();
  },

  doSave: function (component) {
    var action = component.get("c.saveCaseParts"),
      la;

    action.setParams({
      caseParts: component.get("v.parts")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  confirm: function (component, confirmParams) {
    var confirmCmp = component.find("lgnd-confirm");

    return new Promise(function (resolve, reject) {
      component.addEventHandler("c:lgnd_Confirm_Response_Event", function (auraEvent) {
        auraEvent.getParam("theResponse") ? resolve() : reject();
      });
      confirmCmp.showConfirm(confirmParams);
    });
  },

  showToast: function (state, title, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      message: message,
      type: state
    });
    toastEvent.fire();
  }
});
