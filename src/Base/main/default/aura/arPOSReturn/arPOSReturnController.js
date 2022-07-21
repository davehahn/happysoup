({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, false);
    helper.runAction(component, "c.getCDOptions", {}, function (response) {
      component.set("v.cdOptions", response.getReturnValue());
    });
    helper.runAction(component, "c.getWarehouses", {}, function (response) {
      component.set("v.whOptions", response.getReturnValue());
    });
    const empApi = component.find("empApi");
    empApi.onError(
      $A.getCallback((error) => {
        // Error can be any type of error (subscribe, unsubscribe...)
        console.error("EMP API error: ", JSON.stringify(error));
        helper.toggleSpinner(component, true);
      })
    );
  },
  searchAgain: function (component, event, helper) {
    component.set("v.listData", []);
    component.set("v.materials", []);
    component.set("v.materialsAdded", []);
    component.set("v.erpProducts", []);
    component.set("v.grandTotal", 0);
    component.set("v.isERPList", false);
    component.set("v.HideIt", true);
    component.set("v.idFilter", "");
    component.set("v.accountId", "");
    component.set("v.noFoundMessage", "");
  },
  handleFilterSelected: function (component, event, helper) {
    var idFilter = event.getParam("filterId");
    console.log(idFilter);
    // return;
    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.retrieveERPOrders",
      {
        idFilter: idFilter
      },
      function (response) {
        var results = response.getReturnValue();
        results = JSON.parse(results);
        if (results.length > 0) {
          component.set("v.listData", results);
          component.set("v.isERPList", true);
          component.set("v.HideIt", false);
          component.set("v.idFilter", idFilter);
          component.set("v.noFoundMessage", "");
          component.set("v.accountId", results[0].AcctSeed__Account__c);
          component.set("v.erpId", results[0].Id);
          helper.searchERPproductsSingle(component, event, helper);
        } else {
          helper.showToast(
            component,
            "Error",
            "error",
            "The Selected Filter does not have any ERP Order Items to return."
          );
        }
        helper.toggleSpinner(component, false);
      }
    );
  },
  handleAccountSelected: function (component, event, helper) {
    var accountId = event.getParam("accountId");
    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.retrieveERPOrders",
      {
        idFilter: accountId
      },
      function (response) {
        var results = response.getReturnValue();
        results = JSON.parse(results);
        if (results.length > 0) {
          component.set("v.listData", results);
          component.set("v.isERPList", true);
          component.set("v.HideIt", false);
          component.set("v.accountId", accountId);
          component.set("v.noFoundMessage", "");
        } else {
          helper.showToast(component, "Error", "error", "No Completed ERP Orders were found for this Customer.");
        }
        helper.toggleSpinner(component, false);
      }
    );
  },
  processReturn: function (component, event, helper) {
    helper.processRefundStart(component, event, helper);
  },
  processReturn_Old: function (component, event, helper) {
    /// We were accepting multiple projects. but later decided to have only one.
    /// That is why we are returning the user to the first ERP order which is going to be the only one.
    var plist = component.get("v.listData");
    //console.log(plist[0].Id);
    // return;
    helper.toggleSpinner(component, true);
    helper.closeModal(component, event, helper);
    helper.runAction(
      component,
      "c.saveReturnMaterials",
      {
        idAccount: component.get("v.accountId"),
        paymentMethod: component.get("v.cdType"),
        pIdWarehouse: component.get("v.idWarehouse"),
        allMaterials: JSON.stringify(component.get("v.materials"))
      },
      function (response) {
        var state = response.getState();
        if (state != "SUCCESS") {
          helper.closeModal(component, event, helper);
          var errors = response.getError();
          if (errors) {
            helper.toggleSpinner(component, false);
            if (errors[0] && errors[0].message) {
              helper.showToast(component, "Error In Return", "error", errors[0].message);
            } else {
              helper.showToast(component, "Error In Return", "error", "There was an error creating return");
            }
            return;
          }
        }
        var idBill = response.getReturnValue();
        helper.processCOGS(component, event, helper, idBill);
        // var results = response.getReturnValue();
        // helper.toggleSpinner(component, false);
        // var navEvt = $A.get("e.force:navigateToSObject");
        // helper.closeModal( component, event, helper );
        // navEvt.setParams({
        //   "recordId": plist[0].Id,
        //   "slideDevName": "related"
        // });
        // navEvt.fire();
      }
    );
  },
  returnAllMaterials: function (component, event, helper) {
    if (component.get("v.materials").length > 0) helper.returnAllMaterials(component, event, helper);
    else helper.showToast(component, "Error", "error", "Please select some ERP Order Items to return.");
  },
  closeModal: function (component, event, helper) {
    helper.closeModal(component, event, helper);
  },
  returnThisProduct: function (component, event, helper) {
    helper.returnThisProduct(component, event, helper);
  },
  calculateTotalAmount: function (component, event, helper) {
    helper.calculateTotalAmount(component, event);
  },
  removeFromList: function (component, event, helper) {
    helper.removeFromList(component, event);
  },
  searchERPproducts: function (component, event, helper) {
    var erpaccid = event.currentTarget.dataset.erpaccid;
    var erpId = event.currentTarget.dataset.erpid;
    console.log("here:" + erpId);
    helper.toggleSpinner(component, true);
    helper.runAction(
      component,
      "c.retrieveERPProducts",
      {
        erpId: erpId
      },
      function (response) {
        var results = response.getReturnValue();
        component.set("v.accountId", erpaccid);
        results = JSON.parse(results);
        component.set("v.erpProducts", results);
        helper.toggleSpinner(component, false);
      }
    );
  }
});
