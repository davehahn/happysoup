({
  getProduct: function (component, productId) {
    var action = component.get("c.getProduct"),
      la;
    action.setParams({
      id: productId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  findPrice: function (component, productId) {
    var action = component.get("c.getUnitPrice"),
      la;
    console.log("getUnitPrice");
    console.log(productId);
    action.setParams({
      productId: productId
    });

    la = new LightningApex(this, action);
    return la.fire();
  },

  showToast: function (state, title, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      message: message,
      type: state
    });
    toastEvent.fire();
  }
});
