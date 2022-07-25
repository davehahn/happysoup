({
  doInit: function (component) {
    var scope = component.get("v.accountScope");
    if (scope === "dealer" || scope === "supplier") component.set("v.accountIcon", "standard:account");
    else component.set("v.accountIcon", "standard:person_account");
  },

  toggleAccountCard: function (component, event, helper) {
    console.log("toggle: " + component.get("v.accountId"));
    if (component.get("v.accountId") != null) $A.util.removeClass(component.find("account-card"), "slds-hide");
    else $A.util.addClass(component.find("account-card"), "slds-hide");
  },

  accountSelected: function (component, event, helper) {
    helper.createERP(component);
  },

  handleCreateAccount: function (component, event) {
    console.log("handle Create Account");
    var scope = event.getParam("event");
    if (scope === "new") component.set("v.isCreatingNew", true);
    if (scope === "close") component.set("v.isCreatingNew", false);
  },

  handleAccountCreated: function (component, event, helper) {
    console.log("account created");
    component.set("v.accountId", event.getParam("accountId"));
    component.set("v.AccountName", event.getParam("accountName"));
    helper.createERP(component);
  }
});
