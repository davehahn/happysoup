({
  initialize: function (component) {
    this.initData(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.leadOptions", result);
      }),
      $A.getCallback(function (err) {
        LightningUtils.showToast("error", "An error has been encountered", err);
      })
    );
  },

  initData: function (component) {
    var action = component.get("c.getLeadSources"),
      la;
    la = new LightningApex(this, action);
    return la.fire();
  }
});
