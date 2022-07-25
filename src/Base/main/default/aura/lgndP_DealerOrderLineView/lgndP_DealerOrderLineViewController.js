({
  doInit: function (component, event, helper) {
    var params = event.getParam("arguments"),
      spinner = component.find("spinner"),
      result;
    component.set("v.orderGroupId", params.groupId);
    helper.fetchData(component).then(
      $A.getCallback(function (result) {
        $A.util.addClass(spinner, "slds-hide");
        component.set("v.lineData", result);
      }),
      $A.getCallback(function (err) {
        alert(err);
      })
    );
  },

  returnToList: function (component, event, helper) {
    var evt = component.getEvent("cancelEvent");
    evt.fire();
  },

  handleCancelView: function (component, event) {
    component.set("v.lineData", null);
    component.set("v.isViewing", false);
  }
});
