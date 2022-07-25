({
  fetchData: function (component) {
    var action = component.get("c.fetchData"),
      params = {
        acctId: component.get("v.recordId")
      };
    return this.actionHandler(component, action, params);
  },

  actionHandler: function (component, action, params) {
    action.setParams(params);
    var self = this;
    self.toggleIndicator(component);
    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        self.toggleIndicator(component);
        if (state === "SUCCESS") {
          resolve(response.getReturnValue());
        }
        if (state === "INCOMPLETE") {
          reject("Incomplete Transaction");
        }
        if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(errors[0].message);
            } else if (errors[0] && errors[0].pageErrors) {
              reject(errors[0].pageErrors[0].message);
            }
          } else {
            reject("Unknown error");
          }
        }
      });
      $A.enqueueAction(action);
    });
  },

  toggleIndicator: function (component) {
    var indicator = component.find("busy-indicator");
    $A.util.toggleClass(indicator, "hidden");
  }
});
