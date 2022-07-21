({
  fetchAssociatedSerials: function (component) {
    var accountId = component.get("v.accountId"),
      action = component.get("c.fetchSerialNumbersByAccount"),
      la;
    if (accountId == null || accountId === undefined) return Promise.resolve([]);
    action.setParams({
      accountId: component.get("v.accountId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  fetchSerialDetails: function (component, serialId) {
    var action = component.get("c.fetchSerialDetails"),
      la;
    action.setParams({
      serialId: serialId
    });
    la = new LightningApex(this, action);
    return la.fire();
  }
});
