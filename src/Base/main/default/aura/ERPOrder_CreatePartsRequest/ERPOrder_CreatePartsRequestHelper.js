({
  getInitData: function (component) {
    var action = component.get("c.getInitialData"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  getMaterials: function (component) {
    var action = component.get("c.getMaterials"),
      la;
    action.setParams({
      erpId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  createCase: function (component) {
    var action = component.get("c.createPartsRequestCase"),
      la,
      params,
      parts = component.get("v.materials"),
      caseParts = [];
    for (let p of parts) {
      if (p.quantityRequired > 0) {
        var cp = {
          Product__c: p.productId,
          Quantity__c: p.quantityRequired,
          Material__c: p.materialId
        };
        caseParts.push(cp);
      }
    }
    params = {
      casePartsJSON: JSON.stringify(caseParts),
      erpId: component.get("v.recordId"),
      notes: component.get("v.notes")
    };
    console.log(params);
    action.setParams(params);
    la = new LightningApex(this, action);
    return la.fire();
  }
});
