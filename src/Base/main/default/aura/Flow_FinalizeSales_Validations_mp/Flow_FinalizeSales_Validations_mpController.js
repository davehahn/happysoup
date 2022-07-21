({
  doInit: function (component, event, helper) {
    var self = this,
      recordId = component.get("v.recordId");

    if (recordId != null) {
      helper.getERP(component).then(
        $A.getCallback(function (result) {
          console.log(result);
          helper.checkForExistingJournalEntry(component).then(
            $A.getCallback(function (result) {
              helper.checkIfReady(component, event);
            }),
            $A.getCallback(function (err) {
              LightningUtils.errorToast(err);
            })
          );
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
    }
  },

  handleERP: function (component, event, helper) {
    helper.getERP(component).then(
      $A.getCallback(function (result) {
        console.log(result);
        helper.checkForExistingJournalEntry(component);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  next: function (component, event, helper) {
    var step = component.get("v.step");
    step++;
    component.set("v.step", step);
    if (step == 1) {
      helper.checkIfReady(component, event);
    }
  },

  toggleLocationMatch: function (component, event, helper) {
    var match = component.get("v.LocationsMatch");
    component.set("v.LocationsMatch", !match);
  }
});
