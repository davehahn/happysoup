({
  initNewSavings: function (component) {
    var action = component.get("c.fetchNewSavings");
    new LightningApex(this, action).fire().then(
      $A.getCallback(function (result) {
        component.set("v.newSavings", result);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToas(err);
      })
    );
  }
});
