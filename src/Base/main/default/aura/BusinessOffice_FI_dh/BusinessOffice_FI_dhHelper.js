({
  fetchFinancialInstitutionOptions: function (component) {
    var action = component.get("c.fetchFinancialInstitutionOptions"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  updateFinancialInstitution: function (component) {
    var action = component.get("c.updateFinancialInstitution"),
      la;
    action.setParams({
      recordId: component.get("v.recordId"),
      fi_value: component.get("v.financingInstitution")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  toggleSpinner: function (component) {
    var spinner = component.find("fi-spinner");
    $A.util.toggleClass(spinner, "slds-hide");
  }
});
