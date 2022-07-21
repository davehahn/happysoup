({
  isStepOneValid: function (component) {
    var valid = true,
      acctId = component.get("v.accountId"),
      serId = component.get("v.serialNumberId");
    if (acctId === undefined || acctId.length === 0) valid = false;
    if (serId === undefined || serId.length === 0) valid = false;
    component.set("v.stepOneValid", valid);
  },

  isFormValid: function (component) {
    return this.isValid(component.find("requiredField"));
    // return component.find('requiredField').reduce(function (validSoFar, inputCmp) {
    //         inputCmp.showHelpMessageIfInvalid();
    //         return validSoFar && inputCmp.get('v.validity').valid;
    //     }, true);
  },

  isValid: function (inputs) {
    return inputs.reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get("v.validity").valid;
    }, true);
  },

  fetchSerial: function (component, serialId) {
    var action = component.get("c.fetchSerial");

    action.setParams({
      serialId: serialId
    });

    return this.actionHandler.call(this, component, action);
  },

  actionHandler: function (component, action) {
    var self = this;
    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve(response.getReturnValue());
        }
        //else if (cmp.isValid() && state === "INCOMPLETE") {
        else if (state === "INCOMPLETE") {
          // do something
          reject("incomplete");
        }
        //else if (cmp.isValid() && state === "ERROR") {
        else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject("Error message: " + errors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });
      $A.enqueueAction(action);
    });
  },

  caseCreateComplete: function (component) {
    var indicator = component.find("busy-indicator");
    component.set("v.toastContent", { type: "success", message: "Issue Logged!" });
    $A.util.toggleClass(indicator, "hidden");
  },

  resetForm: function (component) {
    var utilityAPI = component.find("utilitybar");
    component.set("v.caseId", "");
    component.set("v.claimType", "");
    component.set("v.subject", "");
    component.set("v.description", "");
    component.set("v.failureDate", "");
    component.set("v.serialNumberId", "");
    component.set("v.accountId", "");
    component.set("v.currentStep", 1);
    utilityAPI.minimizeUtility();
  }
});
