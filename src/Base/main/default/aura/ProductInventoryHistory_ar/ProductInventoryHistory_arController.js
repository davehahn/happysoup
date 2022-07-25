({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.retrieveHistoryDetails",
      {
        mapFilter: {
          idFilter: component.get("v.recordId")
        }
      },
      function (response) {
        var results = response.getReturnValue();
        results = JSON.parse(results);
        component.set("v.listData", results);
      }
    );
    helper.runAction(component, "c.listWarehouses", {}, function (response) {
      component.set("v.whOptions", response.getReturnValue());
    });
  },
  warehouseChanged: function (component, event, helper) {
    helper.runAction(
      component,
      "c.retrieveHistoryDetails",
      {
        mapFilter: {
          idFilter: component.get("v.recordId"),
          idWarehouse: component.get("v.idWarehouse")
        }
      },
      function (response) {
        var results = response.getReturnValue();
        results = JSON.parse(results);
        component.set("v.listData", results);
      }
    );
  },
  changeTotal: function (component) {
    var listData = component.get("v.listData");
    var totalQ = 0;
    for (var i = 0; i < listData.length; i++) totalQ += parseFloat(listData[i].quantity);

    component.set("v.availableQuantity", totalQ);
  }
});
