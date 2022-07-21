({
  doInit: function (component, event, helper) {
    component.set("v.status", "Loading details...");
    helper.clonePromo(component, event);
  }
});
