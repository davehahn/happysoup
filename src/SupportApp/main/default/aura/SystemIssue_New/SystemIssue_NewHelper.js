/**
 * Created by dave on 2020-01-02.
 */

({
  doInit: function (component) {
    console.log("helper.doInit");
    var action = component.get("c.initForm");
    return new LightningApex(this, action).fire();
  },

  isFormValid: function (component) {
    return component.find("requiredField").reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get("v.validity").valid;
    }, true);
  },

  doSubmit: function (component) {
    var action = component.get("c.createIssue"),
      issue = component.get("v.issue");
    action.setParams({
      issue: component.get("v.issue")
    });
    return new LightningApex(this, action).fire();
  },

  doCancel: function (component) {
    var homeEvt = $A.get("e.force:navigateToObjectHome");
    homeEvt.setParams({
      scope: "System_Issue__c"
    });
    homeEvt.fire();
  }
});
