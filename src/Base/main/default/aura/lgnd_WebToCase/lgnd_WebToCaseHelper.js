({
  doInit: function (component) {
    var action = component.get("c.initData");
    return new LightningApex(this, action).fire();
  },

  isFormValid: function (component) {
    return component.find("requiredField").reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get("v.validity").valid;
    }, true);
  },

  submitCase: function (component) {
    var data = {
        caseType: component.get("v.type"),
        reason: component.get("v.reason"),
        priority: component.get("v.priority"),
        subject: component.get("v.subject"),
        description: component.get("v.description"),
        stepsToReproduce: component.get("v.stepsToRepeat"),
        jiraProjectName: component.get("v.jiraProjectName")
      },
      action = component.get("c.saveTheCase");

    action.setParams({
      jsonData: JSON.stringify(data)
    });

    return new LightningApex(this, action).fire();
  },

  caseCreateComplete: function (component) {
    var indicator = component.find("busy-indicator"),
      utilityAPI = component.find("utilitybar");
    component.set("v.type", "");
    component.set("v.priority", "");
    component.set("v.subject", "");
    component.set("v.description", "");
    component.set("v.reason", "");
    component.set("v.stepsToRepeat", "");
    component.set("v.formValid", false);
    component.set("v.currentStep", "one");
    $A.util.toggleClass(indicator, "hidden");
    LightningUtils.showToast("success", "Success", "Issue Logged Successfully!");
    utilityAPI.minimizeUtility();
  }
});
