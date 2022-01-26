/**
 * Created by dave on 2022-01-18.
 */

({
  doInit: function (component, event, helper) {
    var workspaceAPI = component.find("workspace");
    workspaceAPI
      .isConsoleNavigation()
      .then(function (response) {
        component.set("v.inConsoleView", response);
      })
      .catch(function (error) {
        console.log(error);
      });
  },

  doInit2: function( component, event, helper){
   var urlEvent = $A.get("e.force:navigateToURL"),
       recordId = component.get('v.recordId');
       urlEvent.setParams({
         'url': '/lightning/cmp/runtime_sales_lead__convertDesktopConsole?leadConvert__leadId=' + recordId+ '&ws=%2Flightning%2Fr%2FLead%2F'+recordId+'%2Fview'
       });
       urlEvent.fire();
  },

  handleRecordUpdated: function (component, event, helper) {
    var eventParams = event.getParams();
    console.log('handleRecordUpdate')
    if (eventParams.changeType === "LOADED") {
      const company =  component.get("v.leadRecord.Company");
      // record is loaded (render other component which needs record data value)
      console.log("Record is loaded successfully.");
      console.log(
        "record has company " + company
      );
      if( company !== undefined && company !== null  ){
        var urlEvent = $A.get("e.force:navigateToURL"),
            recordId = component.get('v.recordId');
        urlEvent.setParams({
          'url': '/lightning/cmp/runtime_sales_lead__convertDesktopConsole?leadConvert__leadId=' + recordId+ '&ws=%2Flightning%2Fr%2FLead%2F'+recordId+'%2Fview'
        });
        urlEvent.fire();
      }
      else {
        component.set('v.renderForm', true);
      }
    }
  },

  handleNext: function (component, event, helper) {
    component.find("personForm").next();
  },

  handleBack: function (component, event, helper) {
    component.find("personForm").back();
  },

  handleContinue: function (component, event, helper) {
    component.find("personForm").continue();
  },

  handleOppCreated: function (component, event, helper) {
    var inConsole = component.get("v.inConsoleView"),
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
    } else {
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
