({
  initComplete: false,
  recordLoaded: false,
  initialize: function (component) {
    var action = component.get("c.init");
    action.setParams({
      recordId: component.get("v.recordId"),
      fieldName: component.get("v.pickListField")
    });

    return new LightningApex(this, action).fire();
  },
  setup: function (component) {
    if (!component.get("v.isDependentPicklist")) return false;
    if (!this.initComplete) return false;
    if (!this.recordLoaded) return false;
    let record = component.get("v.simpleRecord");
    let ctrlField = component.get("v.controlFieldName");
    let valuesByCtrlField = component.get("v.dependentOptionsByControlField");
    let picklistFieldName = component.get("v.pickListField");
    component.set("v.dependentOptions", valuesByCtrlField[record[ctrlField]]);
    component.set("v.currentValue", record[picklistFieldName]);
    component.set("v.selectedStatus", record[picklistFieldName]);
  },

  saveRecord: function (component, value) {
    var fieldName = component.get("v.pickListField"),
      spinner = component.find("spinner"),
      simpleRecord = component.get("v.simpleRecord");

    simpleRecord[fieldName] = value;
    component.set("v.simpleRecord", simpleRecord);
    $A.util.toggleClass(spinner, "slds-hide");

    component.find("recordHandler").saveRecord(
      $A.getCallback(function (saveResult) {
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
          $A.get("e.force:refreshView").fire();
          $A.util.toggleClass(spinner, "slds-hide");
        } else if (saveResult.state === "INCOMPLETE") {
          LightningUtils.errorToast("User is offline, device doesn't support drafts.");
        } else if (saveResult.state === "ERROR") {
          LightningUtils.errorToast("Problem saving record, error: " + JSON.stringify(saveResult.error));
        } else {
          LightningUtils.errorToast(
            "Unknown problem, state: " + saveResult.state + ", error: " + JSON.stringify(saveResult.error)
          );
        }
      })
    );
  }
});
