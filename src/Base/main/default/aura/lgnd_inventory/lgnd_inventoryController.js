({
  doInit: function (component, event, helper) {
    var action = component.get("c.getUserId");

    // action.setParams({
    // 	// None yet
    // });
    action.setCallback(this, function (response) {
      component.set("v.userId", response.getReturnValue());
    });
    $A.enqueueAction(action);
  },

  productRegistered: function (component, event, helper) {
    if (component.get("v.productRegistered")) {
      component.set("v.serno", "");
      component.find("lgnd_inventory_list").refreshRegistrations();
      document.getElementById("lgnd_registration").classList.add("slds-hide");
      document.getElementById("lgnd_inventory_list").classList.remove("slds-hide");
    }
  }
});
