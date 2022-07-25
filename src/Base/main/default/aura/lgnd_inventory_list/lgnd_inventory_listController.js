({
  doInit: function (component, event, helper) {
    helper.setLocalStorage(component, event);
    component.find("listSelector--Cmp").doInit();
  },

  refreshRegistrations: function (component, event, helper) {
    helper.getRegistrations(component, event);
  },

  transfer: function (component, event, helper) {
    component.set("v.serno", event.currentTarget.value);
  },

  handleListChange: function (component, event, helper) {
    component.set("v.selectedList", event.getParam("listName"));
    component.set("v.listSelectorFilter", event.getParam("filterText"));
    helper.getRegistrations(component, event);
  },

  handleSort: function (component, event, helper) {
    var ele = event.currentTarget,
      workingField = ele.dataset.fieldName,
      sortField = component.get("v.sortField"),
      sortDir = component.get("v.sortDir");

    if (sortDir == "ASC" && workingField == sortField) {
      component.set("v.sortDir", "DESC");
    } else if (sortDir == "DESC" && workingField == sortField) {
      component.set("v.sortDir", "ASC");
    }

    component.set("v.sortField", workingField);

    helper.getRegistrations(component);
  },

  perPageChanged: function (component, event, helper) {
    component.set("v.perPage", event.target.value);
    helper.getRegistrations(component, event);
    localStorage.setItem("perPage", event.target.value);
  },

  pageNumChanged: function (component, event, helper) {
    helper.getRegistrations(component, event);

    var pageNumber = component.get("pageNumber");
    localStorage.setItem("pageNumber", pageNumber);
  },

  nextPage: function (component, event, helper) {
    var currentPage = component.get("v.pageNumber");
    currentPage++;
    component.set("v.pageNumber", currentPage);
    localStorage.setItem("pageNumber", currentPage);
    helper.getRegistrations(component, event);
  },

  prevPage: function (component, event, helper) {
    var currentPage = component.get("v.pageNumber");
    currentPage--;
    component.set("v.pageNumber", currentPage);
    localStorage.setItem("pageNumber", currentPage);
    helper.getRegistrations(component, event);
  },

  handleTableAction: function (component, event, helper) {
    var menuSelection = event.getParam("value").split(":"),
      action = menuSelection[0],
      sernoId = menuSelection[1];
    // e = $A.get('e.c:lgnd_registration_event');

    component.set("v.sernoId", sernoId);

    document.getElementById("lgnd_inventory_list").classList.add("slds-hide");
    document.getElementById("lgnd_registration").classList.remove("slds-hide");

    if (action == "register") {
      component.set("v.registrationTitle", "Register to Customer");
      component.set("v.accountScope", "customer");
    } else if (action == "transfer") {
      component.set("v.registrationTitle", "Transfer to Another Dealer");
      component.set("v.accountScope", "dealer");
    }
    component.set("v.productRegistered", false);

    // e.setParams({'event':'sernoSelected'});
    // e.fire();
  },

  closeAlert: function (component, event, helper) {
    component.set("v.productRegistered", false);
  },

  filterInventory: function (component, event, helper) {
    helper.getRegistrations(component, event);
  },

  filterOnSerno: function (component, event, helper) {
    helper.getRegistrations(component, event);
  }
});
