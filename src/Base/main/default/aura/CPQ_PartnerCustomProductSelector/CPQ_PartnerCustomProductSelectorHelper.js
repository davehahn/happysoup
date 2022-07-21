({
  initNewCustomProduct: function (component) {
    var action = component.get("c.fetchNewCustomProduct");
    new LightningApex(this, action).fire().then(
      $A.getCallback(function (result) {
        component.set("v.newCustomProduct", result);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  }
});
