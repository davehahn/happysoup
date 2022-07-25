({
  runAction: function (component, actionName, params, callback) {
    var action = component.get(actionName);
    action.setParams(params);

    // Register the callback function
    action.setCallback(this, callback);

    // Invoke the service
    $A.enqueueAction(action);
  },
  showToast: function (component, title, type, message) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: title,
      type: type,
      message: message
    });
    toastEvent.fire();
  },
  retrieveTransfers: function (component, event) {
    var self = this;
    self.toggleSpinner(component, true);
    console.log("v.recordId");
    console.log(component.get("v.recordId"));
    self.runAction(
      component,
      "c.retrieveTransfersByERP",
      {
        idERP: component.get("v.recordId")
      },
      function (response) {
        self.toggleSpinner(component, false);
        var results = response.getReturnValue();
        console.log("results");
        console.log(results);
        if (results.isInternal == "true") {
          var listTns = [];
          if (results.listTnsf != null) listTns = JSON.parse(results.listTnsf);
          component.set("v.isInternalPartsOrder", true);
          component.set("v.listDataNew", listTns);
        } else {
          component.set("v.isInternalPartsOrder", false);
        }
      }
    );
  },
  checkIdType: function (component, event) {
    var self = this;
    //self.toggleSpinner(component, true);
    self.runAction(
      component,
      "c.checkId",
      {
        idRecord: component.get("v.recordId")
      },
      function (response) {
        //self.toggleSpinner(component, false);
        var result = response.getReturnValue();
        console.log("result");
        console.log(result);
        component.set("v.recordId", result);
        self.retrieveTransfers(component, event);
      }
    );
  },
  createInvoice: function (component, idTnsf) {
    var self = this;
    self.toggleSpinner(component, true);
    self.runAction(
      component,
      "c.createTransferInvoice",
      {
        idERP: component.get("v.recordId"),
        idTnsf: idTnsf
      },
      function (response) {
        self.toggleSpinner(component, false);
        // Do Nothing
      }
    );
  },
  toggleSpinner: function (component, value) {
    var spinner = component.find("spinnerw");

    //window.setTimeout(
    //$A.getCallback( function() {
    if (value) {
      $A.util.removeClass(spinner, "slds-hide");
    } else {
      $A.util.addClass(spinner, "slds-hide");
    }
    //}););
  }
});
