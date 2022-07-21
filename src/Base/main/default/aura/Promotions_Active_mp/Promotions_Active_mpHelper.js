({
  getPromotions: function (component) {
    var action = component.get("c.getPromotions"),
      la;
    la = new LightningApex(this, action);
    return la.fire().then(function (result) {
      console.log(result);
      component.set("v.promotions", result);
    });
  },

  getPromoItems: function (component, event) {
    var action = component.get("c.getPromoItems"),
      la,
      promoId = event.currentTarget.dataset.product;
    action.setParams({
      promoId: promoId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  createPromoClaim: function (component, event) {
    var action = component.get("c.claimPromoWithoutSerno"),
      la,
      promoItemId = component.get("v.newClaim_promoItem_selected");
    action.setParams({
      promoItemId: promoItemId
    });
    la = new LightningApex(this, action);
    return la.fire();
  }
});
