({
  handleBoatTypeSelected: function (component, event, helper) {
    component.set("v.cpq", helper.unSelectMajorProduct(component));
  },

  handleMajorProductSelected: function (component, event, helper) {
    console.log("majorProductSelected");
    var params = event.getParams();
    helper.fetchMajorProductDetails(component, params.family, params.recordTypeName, params.productId);
  },

  handleOptionChange: function (component, event, helper) {
    console.log("handling optionChange");
    var opt = event.getParams().optionItem;
    helper.updateSaleItems(component, opt);
  }
});
