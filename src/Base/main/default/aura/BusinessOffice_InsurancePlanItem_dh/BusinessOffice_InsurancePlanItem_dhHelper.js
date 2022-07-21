({
  fetchPlanItem: function (component) {
    var action = component.get("c.fetchInsurancePlanItem"),
      la;

    action.setParams({
      productId: component.get("v.productId"),
      taxZoneId: component.get("v.taxZoneId")
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  findCurrentRate: function (component) {
    var rates = component.get("v.rates"),
      coverage = component.get("v.coverageType"),
      term = component.get("v.term"),
      finTerm = component.get("v.finTerm"),
      rateLine,
      isFromQuebec = component.get("v.isFromQuebec");

    for (let r of rates) {
      if (
        (term >= r.Lower_Term__c &&
          term <= r.Upper_Term__c &&
          finTerm >= r.Lower_Finance_Term__c &&
          finTerm <= r.Upper_Finance_Term__c) ||
        (term >= r.Lower_Term__c &&
          term <= r.Upper_Term__c &&
          (r.Lower_Finance_Term__c == null || r.Upper_Finance_Term__c == null))
      ) {
        rateLine = r;
        break;
      }
    }

    if (rateLine !== undefined) {
      component.set("v.termOutOfRange", false);
      if (coverage === "Single") component.set("v.insuranceRate", rateLine.Single__c);
      else if (coverage === "Joint") {
        if (isFromQuebec) component.set("v.insuranceRate", rateLine.Joint_Factored_Result__c);
        else component.set("v.insuranceRate", rateLine.Joint__c);
      } else component.set("v.insuranceRate", null);
    } else {
      component.set("v.termOutOfRange", true);
    }
  },

  handleSelect: function (component) {
    var lineItem = component.get("v.lineItem");
    if (lineItem === undefined || lineItem === null) {
      component.set("v.unitPrice", 0);
    }
  },

  handleUnSelect: function (component) {
    var lineItem = component.get("v.lineItem");
    if (lineItem === undefined || lineItem === null) component.set("v.unitPrice", null);
  }
});
