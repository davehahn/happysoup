({
  getDealerAccounts: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        options = [],
        values = [],
        action = component.get("c.getDealerAccounts"),
        la;
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          for (var i = 0; i < result.length; i++) {
            options.push({
              value: result[i].Id,
              label: result[i].Name
            });
          }
          component.set("v.accounts", options);
          component.set("v.selectedAccounts", null);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  createNewPromotion: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        promotion = component.get("v.promotion"),
        selectedAccounts = component.get("v.selectedAccounts"),
        action = component.get("c.createNewPromotion"),
        la;
      action.setParams({
        promotion: promotion,
        selectedAccounts: selectedAccounts
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          component.set("v.promotion", result);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  getProducts: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        options = [],
        action = component.get("c.getProducts"),
        la;
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          for (var i = 0; i < result.length; i++) {
            options.push({
              value: result[i].Id,
              label: result[i].Name
            });
          }
          component.set("v.availableProducts", options);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  getDetailedProducts: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        prodIds = component.get("v.selectedProducts"),
        promotion = component.get("v.promotion"),
        action = component.get("c.getDetailedProducts"),
        la;
      action.setParams({
        prodIds: prodIds,
        promotion: promotion
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          component.set("v.promoItems", result);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  savePromoAndItems: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        promotion = component.get("v.promotion"),
        promoItems = component.get("v.promoItems"),
        requirements = component.get("v.promotion.Document_Requirements__c"),
        action = component.get("c.savePromoAndItems"),
        la;
      action.setParams({
        promotion: promotion,
        promoItems: promoItems
      });
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  },

  getPromoDocumentationRequirementOptions: function (component) {
    return new Promise(function (resolve, reject) {
      var self = this,
        action = component.get("c.getPromoDocumentationRequirementOptions"),
        la;
      la = new LightningApex(this, action);
      la.fire().then(
        $A.getCallback(function (result) {
          var options = [];
          for (var i = 0; i < result.length; i++) {
            var option = {
              label: result[i],
              value: result[i]
            };
            options.push(option);
          }
          component.set("v.documentationRequirementOptions", options);
          resolve();
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    });
  }
});
