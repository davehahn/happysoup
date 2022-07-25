({
  getProducts: function (component) {
    var action = component.get("c.getProducts"),
      la,
      options = [];
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        for (var i = 0; i < results.length; i++) {
          options.push({
            value: results[i].Id,
            label: results[i].Name
          });
        }
        component.set("v.products", options);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  getAvailablePromotionsByProduct: function (component) {
    var action = component.get("c.getAvailablePromotionsByProduct"),
      la,
      productId = component.get("v.productId"),
      options = [];
    action.setParams({
      productId: productId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        for (var i = 0; i < results.length; i++) {
          options.push({
            value: results[i].Id,
            label: results[i].Promotion__r.Name
          });
        }
        component.set("v.promotions", options);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  getPromotion: function (component) {
    var action = component.get("c.getPromotionViaItem"),
      la,
      promoItemId = component.get("v.promoItemId");
    action.setParams({
      promoItemId: promoItemId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (result) {
        component.set("v.promotion", result);
        var options = result.Promotion__r.Document_Requirements__c.split(";");
        component.set("v.requirements", options);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  claimPromoWithoutSerno: function (component) {
    var action = component.get("c.claimPromoWithoutSerno"),
      la,
      promoItemId = component.get("v.promoItemId"),
      customerId = component.get("v.customerId"),
      options = [];
    action.setParams({
      promoItemId: promoItemId,
      customerId: customerId
    });
    la = new LightningApex(this, action);
    la.fire().then(
      $A.getCallback(function (results) {
        component.set("v.caseId", results.Id);
        component.set("v.stage", 2);
        component.find("spinner").toggle();
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
        component.find("spinner").toggle();
      })
    );
  },

  hideAccountForm: function (component, event) {
    var accountForm = component.find("accountCreationForm");
    $A.util.addClass(accountForm, "slds-hide");
    component.find("lgnd_account_search").set("v.selectionMade", true);
    component.find("lgnd_account_search").set("v.searchQuery", event.getParam("accountName"));
  }
});
