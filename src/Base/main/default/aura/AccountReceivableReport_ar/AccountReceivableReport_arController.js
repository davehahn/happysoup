({
  doInit: function (component, event, helper) {
    helper.runAction(component, "c.getPeriods", {}, function (response) {
      var results = response.getReturnValue();
      component.set("v.donotLoad", true);
      component.set("v.periodOptions", results);
      component.set("v.idPeriod", results[0].Id);
      component.set("v.donotLoad", false);
    });
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
  createReceiptComponent: function (component, event, helper) {
    var selectedItem = event.currentTarget;
    var idAcc = selectedItem.dataset.idaccount;
    $A.createComponent(
      "c:ListAccountsReceipts_ar",
      {
        recordId: idAcc,
        idPeriod: component.get("v.idPeriod")
      },
      function (newcomponent) {
        if (component.isValid()) {
          var body = component.get("v.body");
          body.push(newcomponent);
          component.set("v.body", body);
        }
      }
    );
  },
  createBillComponent: function (component, event, helper) {
    var selectedItem = event.currentTarget;
    var idAcc = selectedItem.dataset.idaccount;
    $A.createComponent(
      "c:ListAccountBillings_ar",
      {
        recordId: idAcc,
        idPeriod: component.get("v.idPeriod")
      },
      function (newcomponent) {
        if (component.isValid()) {
          var body = component.get("v.body");
          body.push(newcomponent);
          component.set("v.body", body);
        }
      }
    );
  },
  removeComponent: function (component, event, helper) {
    var somethingChanged = event.getParam("somethingChanged");
    if (somethingChanged) helper.retrieveAccountDetails(component, event, helper);
    var comp = event.getParam("billComp");
    comp.destroy();
  }
});
