({
  doInit: function (component, event, helper) {
    var spinner = component.find("spinner"),
      fam = component.get("v.productFamily");
    if (fam !== undefined && fam != null && fam.length > 0) {
      spinner.toggle();
      helper
        .selectFamily(component)
        .then(
          $A.getCallback(function () {
            helper.fireValueChangeEvent(component);
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
  },

  handleTypeSelected: function (component, event, helper) {
    component.set("v.value", null);
    var spinner = component.find("spinner"),
      family = event.getParam("family"),
      recordType = event.getParam("recordType");
    component.set("v.productFamily", family);
    component.set("v.productRecordType", recordType);
    spinner.toggle();
    helper
      .selectFamily(component)
      .then(
        $A.getCallback(function () {}),
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

  handleFamilyChange: function (component, event, helper) {
    component.set("v.value", null);
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .selectFamily(component)
      .then(
        $A.getCallback(function () {}),
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

  handleValueChange: function (component, event, helper) {
    helper.fireValueChangeEvent(component);
  }
});
