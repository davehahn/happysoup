({
  doInit: function (component, event, helper) {
    helper.getPricebooks(component);
    helper.getErpPricebook(component);
  },

  next: function (component, event, helper) {
    var step = component.get("v.step");
    step++;
    component.set("v.step", step);
  }
});
