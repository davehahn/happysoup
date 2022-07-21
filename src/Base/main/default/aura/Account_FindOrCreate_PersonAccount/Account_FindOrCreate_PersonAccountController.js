/**
 * Created by dave on 2020-10-02.
 */

({
  doInit: function (component, event, helper) {
    helper.resetCustomer(component);
  },

  afterScripts: function (component, event, helper) {},

  handleAccountSearchResult: function (component, event, helper) {
    console.log("handle account search event");
    const params = event.getParams();
    console.log(JSON.parse(JSON.stringify(params)));
    switch (params.action) {
      case "new":
        component.set("v.displayForm", true);
        break;
      case "edit":
        helper.handleCustomerSelected(component, params.recordId);
        break;
      case "cancel":
        helper.resetCustomer(component);
        component.set("v.displayForm", false);
        break;
      default:
        return false;
    }
  },

  isValid: function (component, event, helper) {
    var requiredFields = component.find("required-form-1"),
      addrForm = component.find("address-form");

    if (typeof addrForm === "undefined") {
      LightningUtils.errorToast("Did you forget to select an account?");
      return false;
    }

    if (requiredFields === null || requiredFields == undefined) requiredFields = [];
    // if we have a single field ( this will be an object not an array )
    if (requiredFields.length === undefined) requiredFields = [requiredFields];

    return requiredFields.reduce(function (validSoFar, inputCmp) {
      inputCmp.showHelpMessageIfInvalid();
      return validSoFar && inputCmp.get("v.validity").valid;
    }, addrForm.isValid());
  },

  doCancel: function (component, event, helper) {
    helper.resetCustomer(component);
    component.set("v.displayForm", false);
  }
});
