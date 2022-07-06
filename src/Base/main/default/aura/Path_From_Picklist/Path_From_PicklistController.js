({
  doInit: function (component, event, helper) {
    helper.initialize(component).then(
      $A.getCallback((result) => {
        helper.initComplete = true;
        console.log("init complete");
        if (result) {
          console.log("we have dependents");
          component.set("v.isDependentPicklist", true);
          component.set("v.controlFieldName", result.controlFieldName);
          component.set("v.dependentOptionsByControlField", result.valueMap);
          helper.setup(component);
        }
      }),
      $A.getCallback((err) => {
        LightningUtils.errorToast("Problem saving record, error: " + err);
      })
    );
  },

  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    if (eventParams.changeType === "LOADED") {
      helper.recordLoaded = true;
      helper.setup(component);
    }
  },

  handleButton: function (component, event, helper) {
    console.log("handleButton");
    let selectedStatus = component.get("v.selectedStatus");
    let currentStatus = component.get("v.currentValue");
    let options = component.get("v.dependentOptions");
    let value =
      selectedStatus == currentStatus
        ? options[options.indexOf(selectedStatus) + 1]
        : selectedStatus;
    helper.saveRecord(component, value);
  },

  pathClick: function (component, event, helper) {
    event.preventDefault();
    let selectedStatus = event.getSource().get("v.value");
    let currentStatus = component.get("v.currentValue");
    component.set("v.selectedStatus", selectedStatus);
  },

  handleSelect: function (component, event, helper) {
    event.preventDefault();
    const readOnly = component.get("v.readOnly");
    if (readOnly) return;
    helper.saveRecord(component, event.getParam("detail").value);
  },

  reloadRecord: function (component, event, helper) {
    component.find("recordHandler").reloadRecord(true);
  }
});
