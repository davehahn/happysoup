({
  openModal: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .fetchSetupData(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.initData", result);
          if (Object.keys(result).indexOf("serialId") >= 0) {
            console.log("we have a serial Number");
            component.set("v.serialNumberId", result.serialId);
            component.set("v.serialNumberName", result.serialNumber);
            component.set("v.serialProductName", result.serialProduct);
            component.set("v.useErpSerial", true);
            component.set("v.modalOpen", true);
          } else {
            console.log("no serial number here");
            component.set("v.serialNumberId", "");
            helper.loadSerialSelector(component);
          }
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          spinner.toggle();
        })
      );
  },

  closeModal: function (component, event, helper) {
    component.set("v.modalOpen", false);
  },

  revertClick: function (component, event, helper) {
    var initData = component.get("v.initData"),
      ele = component.find("selector");

    ele.set("v.body", []);
    /* small delay to give LightningLookup to be fully removed from the page
       without it, its change handle of serialNumberId will fire and
       remove the value
    */
    setTimeout(
      $A.getCallback(function () {
        component.set("v.serialNumberId", initData.serialId);
        component.set("v.serialNumberName", initData.serialNumber);
        component.set("v.serialProductName", initData.serialProduct);
        component.set("v.useErpSerial", true);
      }),
      50
    );
  },

  useDifferentSerialClick: function (component, event, helper) {
    component.set("v.serialNumberId", null);
    component.set("v.serialNumberName", null);
    component.set("v.serialProductName", null);
    helper.loadSerialSelector(component);
  },

  handleSave: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .saveRecord(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.modalOpen", false);
          LightningUtils.showToast("success", "Success", "Prepaid service was created!");
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          spinner.toggle();
        })
      );
  }
});
