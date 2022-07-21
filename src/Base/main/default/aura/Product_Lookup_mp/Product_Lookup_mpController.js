({
  search: function (component, event, helper) {
    console.log("search");
    console.log("query = " + component.get("v.query"));
    var pause = component.get("v.pause");
    if (!pause) helper.getProducts(component, event);
  },

  clickProduct: function (component, event, helper) {
    console.log("clickProduct");
    console.log(event.currentTarget.dataset.productid);
    component.set("v.pause", true);
    component.set("v.selectionId", event.currentTarget.dataset.productid);
    component.set("v.query", event.currentTarget.dataset.name);
    helper.toggle(component.find("name_combobox"), "close");
    component.set("v.pause", false);
  },

  handleSelectionChange: function (component, event, helper) {
    var selectId = component.get("v.selectionId");
    if (selectId === null) component.set("v.query", null);
  }
});
