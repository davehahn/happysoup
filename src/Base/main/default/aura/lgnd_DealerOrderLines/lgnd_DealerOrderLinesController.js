({
  doInit: function (component, event, helper) {
    helper
      .getUserDetails(component)
      .then(
        $A.getCallback(function (result) {
          component.set("v.userType", result.userType);
          component.set("v.sessionId", result.sessionId);
          component.set("v.bookingOrderStartMonthDay", result.bookingStartMonthDay);
          if (result.uiTheme !== "Theme3") component.set("v.inCommunity", false);
          return helper.fetchDealerOrder(component);
        }),
        $A.getCallback(function (err) {
          alert(err);
        })
      )
      .then(
        $A.getCallback(function (result) {
          component.set("v.dealerOrder", result);
          component.find("dealerOrderLines--Cmp").doInit();
        }),
        $A.getCallback(function (err) {
          alert(err);
        })
      );
  },

  handleDetailsBtn: function (component) {
    var currentView = component.get("v.currentView"),
      id = component.get("v.dealerOrder").Id;
    if (currentView === "list") {
      component.set("v.currentView", "details");
      component.set("v.detailsBtnText", "Less Details");
      component.find("dealerOrderLinesDetails--Cmp").doInit();
    }
    if (currentView === "details") {
      component.set("v.currentView", "list");
      component.set("v.detailsBtnText", "More Details");
      component.find("dealerOrderLines--Cmp").doInit();
    }
  },

  handleAction: function (component, event, helper) {
    var params = event.getParams(),
      id = params.id,
      action = params.action;

    if (action === "edit") {
      component.set("v.currentView", "edit");
      component.find("dealerOrderBuildBoat--Cmp").doInitForEdit(id);
    }
    if (action === "view") {
      component.set("v.isViewing", true);
      component.find("dealerOrderLineView--Cmp").doInit(id);
    }
    if (action === "add") {
      component.set("v.currentView", "edit");
      component.find("dealerOrderBuildBoat--Cmp").doInit();
    }
  },

  handleIndicator: function (component, event, helper) {
    var params = event.getParams(),
      indicator = component.find("busy-indicator");

    if (params.messageOnly) {
      indicator.setMessage(params.message);
    } else {
      indicator.toggle(params.message);
    }
  },

  handleViewChange: function (component, event, helper) {
    if (event.getParam("value") == true) {
      component.set("v.currentView", "view");
    } else {
      component.set("v.currentView", "list");
      component.find("dealerOrderLines--Cmp").doInit();
    }
  },

  handleEditComplete: function (component, event, helper) {
    let status = event.getParam("status");
    const isFactoryStore = true; //component.get('v.dealerOrder').Account__r.Is_Internal__c;
    if (status === "cancel") {
      helper.returnToLineView(component);
    }
    if (status === "complete") {
      if (isFactoryStore) {
        component.find("busy-indicator").toggle();
        helper.returnToLineView(component);
      } else {
        helper.handleApplyPartnerProgram(component);
      }
    }
  }
});
