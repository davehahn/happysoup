({
  doInit: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
  },

  afterScripts: function (component, event, helper) {
    var spinner = component.find("spinner");
    helper
      .fetchData(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.currentRegistration", result.currentRegistration);
          component.set("v.registrations", result.registrations);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          spinner.toggle();
          component.set("v.dataLoaded", true);
        })
      );
  },

  navToAccount: function (component, event) {
    var accountId = event.currentTarget.dataset.accountId,
      evt = $A.get("e.force:navigateToSObject");
    evt.setParams({
      recordId: accountId
    });
    evt.fire();
  }
});
