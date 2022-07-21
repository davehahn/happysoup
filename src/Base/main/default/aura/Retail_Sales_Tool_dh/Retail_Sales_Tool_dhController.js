({
  doInit: function (component, event, helper) {
    helper.inConsole(component).then((result) => {
      component.set("v.inConsoleView", result);
    });
  },

  handleSaleTypeSelect: function (component, event, helper) {
    var saleType = event.currentTarget.dataset.accountType;
    component.set("v.saleType", saleType);
  },

  handleOppCreated: function (component, event, helper) {
    var fromCPQ = component.get("v.fromCPQ"),
      inConsole = component.get("v.inConsoleView"),
      oppId = event.getParam("opportunityId"),
      focusedTabId,
      urlEvent;

    if (inConsole) {
      var workspaceAPI = component.find("workspace");
      workspaceAPI
        .getFocusedTabInfo()
        .then((response) => {
          focusedTabId = response.tabId;
          return workspaceAPI.openTab({
            url: `/apex/BoatConfigurator?opportunity_id=${oppId}`,
            focus: true
          });
        })
        .then((response) => {
          workspaceAPI.closeTab({ tabId: focusedTabId });
        })
        .catch(function (error) {
          console.log(error);
        });
    } else if (!fromCPQ) {
      urlEvent = $A.get("e.force:navigateToURL");
      if (urlEvent) {
        urlEvent.setParams({
          url: "/apex/BoatConfigurator?opportunity_id=" + oppId
        });
        urlEvent.fire();
      } else {
        window.location = "/apex/BoatConfigurator?opportunity_id=" + oppId;
      }
    }
  }
});
