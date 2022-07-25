({
  afterScripts: function (component, event, helper) {
    helper
      .findPermissions(component)
      .then(
        $A.getCallback(function (perms) {
          console.log(perms);
          component.set("v.isLocked", perms.isLocked);
          component.set("v.canCreate", perms.canCreate);
          component.set("v.canDelete", perms.canDelete);
          return helper.fetchCaseParts(component);
        }),
        $A.getCallback(function (err) {
          helper.showToast("error", "There was an error", err);
        })
      )

      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.caseParts", result);
          component.set("v.casePartsCount", result.length);
          component.set("v.loaded", true);
        }),
        $A.getCallback(function (err) {
          helper.showToast("error", "There was an error", err);
        })
      );
  },

  gotoRelatedList: function (component, event, helper) {
    var relatedListEvent = $A.get("e.force:navigateToRelatedList");
    relatedListEvent.setParams({
      relatedListId: "Case_Parts__r",
      parentRecordId: component.get("v.recordId")
    });
    relatedListEvent.fire();
  },

  viewProduct: function (component, event, helper) {
    var recordId = event.currentTarget.dataset.recordId,
      nav = $A.get("e.force:navigateToSObject");

    nav
      .setParams({
        recordId: recordId
      })
      .fire();
  },

  handleTableAction: function (component, event, helper) {
    var menuSelection = event.getParam("value").split(":"),
      action = menuSelection[0],
      recordId = menuSelection[1];

    if (action == "delete") helper.deleteRecordRow(component, recordId);
    if (action == "edit") helper.editRow(recordId);
  },

  openNewForm: function (component, event, helper) {
    component.set("v.modalOpen", true);
  },

  closeNewForm: function (component, event, helper) {
    component.set("v.modalOpen", false);
  },

  saveParts: function (component, event, helper) {
    component.set("v.modalOpen", false);
    var spinner = component.find("spinner");
    $A.util.toggleClass(spinner, "slds-hide");
    helper.doSave(component).then(
      $A.getCallback(function () {
        $A.util.toggleClass(spinner, "slds-hide");
        $A.get("e.force:refreshView").fire();
        helper.showToast("success", "Success", "Parts where added successfully!");
      }),
      $A.getCallback(function (err) {
        $A.util.toggleClass(spinner, "slds-hide");
        component.set("v.modalOpen", true);
        helper.showToast("error", "There was an error", err);
      })
    );
  }
});
