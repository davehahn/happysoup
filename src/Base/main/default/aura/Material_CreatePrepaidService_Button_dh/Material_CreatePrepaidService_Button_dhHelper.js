({
  fetchSetupData: function (component) {
    var action = component.get("c.initData"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  loadSerialSelector: function (component) {
    component.set("v.useErpSerial", false);
    component.set("v.modalOpen", true);
    var ele = component.find("selector");
    $A.createComponent(
      "c:LightningLookup",
      {
        type: "GMBLASERP__Serial_Number__c",
        label: "Search for Serial Number",
        sobjectId: component.getReference("v.serialNumberId"),
        value: component.getReference("v.serialNumberName"),
        secondaryField: "Product_Name__c"
      },
      function (cmp, status, errorMessage) {
        if (status === "SUCCESS") {
          console.log("success loading component");
          console.log(ele);
          console.log("after set attr");
          ele.set("v.body", cmp);
          console.log("after add cmp");
        } else if (status === "INCOMPLETE") {
          LightningUtils.errorToast("No response from server or client is offline.");
          // Show offline error
        } else if (status === "ERROR") {
          LightningUtils.errorToast(errorMessage);
          // Show error message
        }
      }
    );
  },

  saveRecord: function (component) {
    var action = component.get("c.saveRecord"),
      initData = component.get("v.initData"),
      la,
      params = {
        productId: initData.productId,
        accountId: initData.accountId,
        erpId: initData.erpId,
        serialId: component.get("v.serialNumberId"),
        quantity: initData.quantity
      };

    action.setParams(params);

    la = new LightningApex(this, action);
    return la.fire();
  }
});
