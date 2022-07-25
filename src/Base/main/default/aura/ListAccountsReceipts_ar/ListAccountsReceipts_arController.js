({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    helper.retrieveAccountReceipts(component, event, helper);
    component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0}");
  },
  retrieveAccountReceipts: function (component, event, helper) {
    helper.retrieveAccountReceipts(component, event, helper);
  },
  rowSelected: function (component) {
    var billTable = component.find("billDataTable");
    var table;
    if (billTable != undefined && billTable.length > 1) {
      for (var i = billTable.length; i == 1; i--) billTable[i].destroy();

      table = billTable[1];
    } else table = billTable;
    // var table = component.find('billDataTable');
    if (table != undefined) {
      var selections = table.getSelectedRows();
      component.set("v.hasSelections", selections.length > 0);
    } else component.set("v.hasSelections", false);

    console.log(table);
  },
  createApplyCRSelect: function (component, event, helper) {
    var selectedMenuItemValue = event.getParam("value");
    var arrVals = selectedMenuItemValue.split("__");
    var crId = arrVals[0];
    var applyType = arrVals[1];
    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.applyCashReceipts",
      {
        idAccount: component.get("v.recordId"),
        idCR: crId,
        applyType: applyType
      },
      function (response) {
        helper.toggleSpinner(component, false);
        var state = response.getState();

        if (state != "SUCCESS") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              helper.showToast(component, "Error Applying Cash Receipt", "error", errors[0].message);
            } else {
              helper.showToast(
                component,
                "Error Applying Cash Receipt",
                "error",
                "There was an error applying balance."
              );
            }
          }
          return;
        }
        if (component.get("v.reloadAfterSuccess")) helper.retrieveAccountReceipts(component, event, helper);
        component.set("v.dmlSuccess", true);
        helper.showToast(component, "Applied", "success", "Cash Receipt successfully applied.");
      }
    );
  },
  removeComponent: function (component, event, helper) {
    //get event and set the parameter of Aura:component type, as defined in the event above.
    var compEvent = component.getEvent("RemoveComponent");
    compEvent.setParams({
      billComp: component,
      somethingChanged: component.get("v.dmlSuccess")
    });
    compEvent.fire();
  },
  closeToast: function (component, event, helper) {
    var toast = component.find("toast");

    window.setTimeout(
      $A.getCallback(function () {
        $A.util.addClass(toast, "slds-hide");
      })
    );
  }
});
