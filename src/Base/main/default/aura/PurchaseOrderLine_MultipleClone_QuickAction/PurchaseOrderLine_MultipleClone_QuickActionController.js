({
  closeModal: function (component, event, helper) {
    helper.closeModal();
  },

  doClone: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .doClone(component)
      .then(
        $A.getCallback(function (result) {
          LightningUtils.showToast(
            "success",
            "Success!",
            component.get("v.lineCount") + " Purchase Order Lines have been created"
          );
          var evt = $A.get("e.force:navigateToSObject");
          evt
            .setParams({
              recordId: result
            })
            .fire();
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
