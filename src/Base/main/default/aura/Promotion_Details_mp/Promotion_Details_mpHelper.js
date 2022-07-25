({
  getClaimDetails: function (component) {
    console.log("getClaimDetails");
    var self = this,
      action = component.get("c.getClaimDetails"),
      recordId = component.get("v.recordId");
    action.setParams({
      caseId: recordId
    });
    return new LightningApex(self, action).fire();
  }
});
