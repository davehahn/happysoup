({
  saveJob: function (component) {
    var self = this,
      job = component.get("v.job"),
      product = component.get("v.product"),
      productId,
      action = component.get("c.createNewJob");

    if (product != null) {
      productId = product.Id;
    }

    action.setParams({
      job: job,
      productId: productId
    });

    self.actionHandler(action, false).then(function (job) {
      component.set("v.openNewForm", false);
    });
  },

  searchProducts: function (component, event) {
    var self = this,
      action = component.get("c.searchProducts"),
      query = component.get("v.searchQuery");

    action.setParams({
      query: query
    });

    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        if (results.length > 0) {
          $A.util.removeClass(component.find("name_combobox"), "slds-is-closed");
          $A.util.addClass(component.find("name_combobox"), "slds-is-open");
        } else {
          $A.util.addClass(component.find("name_combobox"), "slds-is-closed");
          $A.util.removeClass(component.find("name_combobox"), "slds-is-open");
        }
        component.set("v.searchResults", results);
      }),
      $A.getCallback(function (err) {
        console.log(err);
        component.set("v.lockCompleted", false);
        LightningUtils.errorToast(err);
      })
    );
  },

  selectProduct: function (component, event) {
    console.log("helper.selectProduct");
    console.log(event);
    var self = this,
      action = component.get("c.getProduct"),
      productId = event.srcElement.parentElement.parentElement.parentElement.id;

    console.log(productId);

    action.setParams({
      productId: productId
    });

    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (result) {
        console.log("selected product");
        console.log(result);
        component.set("v.product", result);
      }),
      $A.getCallback(function (err) {
        console.log(err);
        component.set("v.lockCompleted", false);
        LightningUtils.errorToast(err);
      })
    );
  },

  actionHandler: function (action, deserialize) {
    console.log("helper.actionHandler");
    var self = this;
    return new Promise(function (resolve, reject) {
      action.setCallback(self, function (response) {
        var state = response.getState();
        console.log(state);
        if (state === "SUCCESS") {
          var result = response.getReturnValue();
          if (typeof result === "string") {
            try {
              result = result.replace(/(\r|\n)/gm, "");
              result = JSON.parse(result);
            } catch (err) {
              console.log(err);
            }
          }
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
