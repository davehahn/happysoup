({
  lookupProjects: function (component, event, helper) {
    // helper.toggleSpinner(component, true);
    var searchQuery = component.get("v.searchQuery"),
      combobox = component.find("name_combobox"),
      alreadySelected = component.get("v.selectionMade");

    if (searchQuery == "" || searchQuery.length <= 2) {
      component.set("v.filterId", false);
      component.set("v.selectionMade", false);
      helper.toggle(combobox, "close");
    } else {
      helper.runAction(
        component,
        "c.searchProjects",
        {
          searchString: searchQuery
        },
        function (response) {
          var results = response.getReturnValue();
          console.log(results);
          if (results.length > 0) {
            component.set("v.accountList", results);
            helper.toggle(combobox, "open");
          } else {
            component.set("v.accountList", "");
            helper.toggle(combobox, "close");
          }
          // helper.toggleSpinner(component, false);
        }
      );
    }
  },

  clickDropDown: function (component, event, helper) {
    component.set("v.selectionMade", true);

    var selectedItem = event.currentTarget,
      filterId = selectedItem.dataset.filterid,
      combobox = component.find("name_combobox");

    helper.toggle(combobox, "close");

    component.set("v.searchQuery", selectedItem.dataset.name);
    component.set("v.filterId", filterId);

    var evt = component.getEvent("filterSelectedEvent");
    evt
      .setParams({
        filterId: component.get("v.filterId")
      })
      .fire();
  },
  close: function (component, event, helper) {
    var element = component.find("name_combobox"),
      accountList = component.get("v.accountList");

    console.log("l: " + accountList.length);
    if (accountList.length < 1) {
      helper.toggle(element, "close");
    }
  }
});
