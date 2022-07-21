({
  save: function (component, event, helper) {
    helper.saveJob(component);
  },

  back: function (component, event, helper) {
    component.set("v.openNewForm", false);
  },

  search: function (component, event, helper) {
    helper.searchProducts(component, event);
  },

  clickProduct: function (component, event, helper) {
    console.log("clickProduct");
    $A.util.removeClass(component.find("name_combobox"), "slds-is-open");
    $A.util.addClass(component.find("name_combobox"), "slds-is-closed");
    helper.selectProduct(component, event);
  }
});
