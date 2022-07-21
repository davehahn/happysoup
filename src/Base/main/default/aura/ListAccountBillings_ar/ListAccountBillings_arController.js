({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    component.set("v.columns", [
      { label: "Name", fieldName: "Name", type: "text" },
      { label: "ERP Order(s)", fieldName: "billProject", type: "text" },
      { label: "Balance", fieldName: "billBalance", type: "currency", typeAttributes: { currencyCode: "CAD" } }
    ]);
    helper.runAction(component, "c.getOptions", {}, function (response) {
      component.set("v.options", response.getReturnValue());
    });
    helper.retrieveAccountBillings(component, event, helper);
    component.set("v.cssCustomStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0}");
  },
  retrieveAccountBillings: function (component, event, helper) {
    helper.retrieveAccountBillings(component, event, helper);
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
  receiveBillings: function (component, event, helper) {
    var typeSelect = component.find("receiptTypes").get("v.value");
    if (typeSelect == undefined || typeSelect == "") {
      helper.showToast(component, "Receipt Type.", "error", "Please Select Receipt Type.");
      return;
    }
    // var table = component.find('billDataTable');
    var billTable = component.find("billDataTable");
    var table;
    if (billTable != undefined && billTable.length > 1) {
      table = billTable[1];
    } else table = billTable;
    var billIds = [];
    for (var bill of table.getSelectedRows()) billIds.push(bill.Id);

    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.receiveBilling",
      {
        idAccount: component.get("v.recordId"),
        idBills: billIds,
        paymentMethod: typeSelect
      },
      function (response) {
        helper.toggleSpinner(component, false);
        var state = response.getState();
        // console.log(response);
        if (state != "SUCCESS") {
          var errors = response.getError();
          // console.log(errors);
          if (errors) {
            if (errors[0] && errors[0].message) {
              helper.showToast(component, "Error Receiving Bills", "error", errors[0].message);
            } else {
              helper.showToast(component, "Error Receiving Bills", "error", "There was an error Receiving Bills.");
            }
          }
          return;
        }
        if (component.get("v.reloadAfterSuccess")) helper.retrieveAccountBillings(component, event, helper);
        component.set("v.dmlSuccess", true);
        helper.showToast(component, "Received", "success", "Billings were received successfully.");
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
