({
  clickCreateAccount: function (component, event, helper) {
    var accountSpinner = component.find("accountSpinner");
    $A.util.toggleClass(accountSpinner, "slds-hide");
    helper.createLead(component, event);
  },

  cancelCreateAccount: function (component, event, helper) {
    var myEvent = component.getEvent("lgnd_registration_event");
    helper.clearForm(component);
    myEvent.setParams({ event: "close" });

    myEvent.fire();
  },

  checkValidity: function (component, event, helper) {
    component.set("v.formValid", helper.isFormValid(component));
  }
});
