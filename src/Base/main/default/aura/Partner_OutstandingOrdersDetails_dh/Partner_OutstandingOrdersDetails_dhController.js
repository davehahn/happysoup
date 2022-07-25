({
  doInit: function (component) {
    var oType = component.get("v.orderType");
    oType = oType.charAt(0).toUpperCase() + oType.slice(1);
    component.set("v.title", "Outstanding " + oType + " Orders");
  },

  afterScripts: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .fetchDetails(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.orders", result);
          component.set("v.modalOpen", true);
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

  recordClick: function (component, event, helper) {
    var recordId = event.currentTarget.dataset.recordId,
      evt = $A.get("e.force:navigateToSObject");

    evt
      .setParams({
        recordId: recordId
      })
      .fire();
  }
});
