({
  doInit: function (component, event, helper) {
    helper.runAction(component, "c.getPeriods", {}, function (response) {
      var results = response.getReturnValue();
      component.set("v.donotLoad", true);
      component.set("v.periodOptions", results);
      component.set("v.donotLoad", false);
      component.set("v.idPeriod", results[0].Id);
    });
    // helper.runAction(component, "c.getAccountTypes", {}, function(response) {
    //     var results = response.getReturnValue();
    //     component.set("v.donotLoad",true);
    //     component.set("v.accountTypes", JSON.parse(results));
    //     component.set("v.donotLoad",false);
    //     console.log();
    //     // component.set("v.idAccRecordType",results[0].Id);
    // });
    component.set("v.columns", [
      { label: "Type", fieldName: "type", type: "text" },
      { label: "Source Name", fieldName: "sourceName", type: "text" },
      { label: "Amount", fieldName: "txnAmount", type: "currency", typeAttributes: { currencyCode: "CAD" } }
    ]);
    // helper.retrieveAccountDetails(component, event, helper);
  },
  sortTry: function (component, event, helper) {
    var selectedItem = event.currentTarget;
    var datalabel = selectedItem.dataset.label;
    var tData = component.get("v.transactionData");
    tData.sort(function (obj1, obj2) {
      // return obj1[datalabel] - obj2[datalabel];
      return obj1[datalabel] === obj2[datalabel] ? 0 : obj1[datalabel] > obj2[datalabel] ? 1 : -1;
    });
    component.set("v.transactionData", tData);
  },
  retrieveAccountDetails: function (component, event, helper) {
    helper.retrieveAccountDetails(component, event, helper);
  },
  previousPeriod: function (component, event, helper) {
    helper.previousPeriod(component, event, helper);
  },
  nextPeriod: function (component, event, helper) {
    helper.nextPeriod(component, event, helper);
  },
  openModal: function (component, event, helper) {
    helper.openModal(component, event, helper);
  },
  closeModal: function (component, event, helper) {
    helper.closeModal(component, event, helper);
  }
});
