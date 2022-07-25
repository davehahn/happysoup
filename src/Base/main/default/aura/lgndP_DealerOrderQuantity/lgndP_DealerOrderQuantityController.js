({
  navNext: function (component, event, helper) {
    var cmpEvent = component.getEvent("navEvent");
    cmpEvent.setParams({ firedBy: 2, navigateTo: 3 });
    cmpEvent.fire();
  },

  navBack: function (component, event, helper) {
    var cmpEvent = component.getEvent("navEvent");
    cmpEvent.setParams({ firedBy: 2, navigateTo: 1 });
    cmpEvent.fire();
  }
});
