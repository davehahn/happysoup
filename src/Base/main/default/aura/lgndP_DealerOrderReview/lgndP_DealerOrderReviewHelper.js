({
  editOrderRow: function (component, groupId) {
    var nav = $A.get("e.c:lgndP_DealerOrderNav_Event");
    nav.setParams({ firedBy: 2, navigateTo: 1, groupId: groupId });
    nav.fire();
  },

  viewOrderRow: function (component, groupId) {
    component.set("v.currentView", "view");
    component.find("dealerOrderLineView--Cmp").doInit(groupId);
  }
});
