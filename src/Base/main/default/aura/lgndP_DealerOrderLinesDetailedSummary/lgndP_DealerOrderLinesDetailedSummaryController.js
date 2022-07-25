({
  autoInit: function (component, event, helper) {
    var recordId = component.get("v.recordId");
    if (recordId !== null) component.doInit();
  },

  doInit: function (component, event, helper) {
    helper.fetchOrderDetails(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.boats", result.boats);
        component.set("v.motors", result.motors);
        component.set("v.trailers", result.trailers);
        component.set("v.trollingMotors", result.trollingMotors);
        component.set("v.options", result.options);
        component.set("v.fees", result.fees);
        component.set("v.discounts", result.discounts);
        component.set("v.mercuryMotors", result.mercuryMotors);
        helper.calcTotals(component);
      }),
      $A.getCallback(function (err) {
        alert(err);
      })
    );
  },
  handleListCollapse: function (component, event, helper) {
    var containerName = event.getSource().get("v.name"),
      ele = component.find(containerName);
    $A.util.toggleClass(ele, "collapse");
  }
});
