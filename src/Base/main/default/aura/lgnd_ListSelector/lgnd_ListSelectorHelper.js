({
  toggleMenu: function (component) {
    var menu = component.find("theMenu");
    $A.util.toggleClass(menu, "slds-is-open");
  },

  fireSelectEvent: function (component) {
    var filterMap = component.get("v.filterMap"),
      curVal = component.get("v.value"),
      evt = $A.get("e.c:lgnd_ListSelector_Event");
    if (curVal !== undefined && curVal !== null && curVal.length > 0) {
      evt.setParams({ filterText: filterMap[curVal], listName: curVal }).fire();
    }
  }
});
