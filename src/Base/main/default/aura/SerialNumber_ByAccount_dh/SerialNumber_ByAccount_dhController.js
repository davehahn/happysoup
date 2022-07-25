({
  doInit: function (component, event, helper) {
    var cols = [
      { label: "Ser. Number", fieldName: "serialName", type: "text", actions: {} },
      { label: "Model", fieldName: "productName", type: "text", actions: {} },
      { label: "Lot/Year", fieldName: "lotName", type: "text", actions: {} },
      { label: "Last W/O type", fieldName: "workOrderRecordType", actions: {} }
    ];
    component.set("v.serialTableCols", cols);
    component.set("v.serialNumberData", []);
    component.set("v.selectedRows", []);
  },

  afterScripts: function (component, event, helper) {
    helper.fetchAssociatedSerials(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.serialNumberData", result);
        if (result === null || result.length === 0) {
          console.log(result.length);
          component.set("v.searchEnabled", true);
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleAccountChange: function (component, event, helper) {
    component.set("v.selectedSerial", null);
    component.set("v.searchEnabled", false);
    helper.fetchAssociatedSerials(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.serialNumberData", result);
        if (result === null || result.length === 0) {
          console.log(result.length);
          component.set("v.searchEnabled", true);
        }
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleSerialSelect: function (component, event, helper) {
    var selectedRows = event.getParam("selectedRows");
    component.set("v.selectedRows", selectedRows);
    if (selectedRows === null || selectedRows === undefined || selectedRows.length === 0) {
      component.set("v.selectedSerial", null);
      return false;
    }

    component.set("v.gettingSerialInfo", true);
    helper.fetchSerialDetails(component, selectedRows[0].idSerial).then(
      $A.getCallback(function (result) {
        console.log(result);
        component.set("v.selectedSerial", result);
        component.set("v.gettingSerialInfo", false);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  clearTableSelection: function (component) {
    component.set("v.selectedRows", []);
    component.set("v.selectedSerial", null);
  },

  enableSearch: function (component) {
    component.set("v.searchEnabled", true);
    component.set("v.selectedRows", []);
    component.set("v.selectedSerial", null);
  },

  cancelSearch: function (component) {
    component.set("v.searchEnabled", false);
  },

  setSerial: function (component) {
    var selectedSerial = component.get("v.selectedSerial");
    console.log(selectedSerial.Id);
    component.set("v.serialNumberId", selectedSerial.Id);
    component.set("v.serialNumber", selectedSerial.Name);
  }
});
