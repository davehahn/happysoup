({
  fetchLocationInfo: function (component) {
    var action = component.get("c.fetchBinLoactionDetails");
    action.setParams({
      prodId: component.get("v.recordId")
    });
    return this.actionHandler.call(this, action, true);
  },

  fetchInventory: function (component) {
    var action = component.get("c.fetchWarehouseInventory"),
      params = {
        prodId: component.get("v.recordId"),
        whName: component.get("v.selectedWarehouse")
      };
    console.log(params);
    action.setParams(params);
    return this.actionHandler.call(this, action, true);
  },

  actionHandler: function (action, deserialize) {
    var self = this;
    console.log(self);
    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var result = deserialize ? JSON.parse(response.getReturnValue()) : response.getReturnValue();
          resolve(result);
        }
        if (state === "INCOMPLETE") {
          reject("incomplete");
        }
        if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject("Error message: " + errors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });

      $A.enqueueAction(action);
    });
  }
});
