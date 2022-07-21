({
  doInit: function (component, event, helper) {
    var alwaysEditFields = component.get("v.alwaysEditFields");
    try {
      component.set("v.alwaysEditFields_List", alwaysEditFields.split(","));
    } catch (err) {
      component.set("v.alwaysEditFields_List", []);
    }
    helper.initialize(component);
  },

  returnToList: function (component, event, helper) {
    helper.returnToList(component);
  },

  cancelAlwaysEdit: function (component) {
    component.set("v.displayAlwaysEditForm", false);
  },

  editHandler: function (component, event, helper) {
    var editURL = component.get("v.editURL"), // /parts-order-edit',
      recordId = component.get("v.recordId"),
      alwaysEditFields_List = component.get("v.alwaysEditFields_List"),
      evt;

    if (helper.evaluateEditCriteria(component)) {
      if ($A.util.isEmpty(editURL)) {
        evt = $A.get("e.force:editRecord");
        evt.setParams({
          recordId: recordId
        });
      } else {
        evt = $A.get("e.force:navigateToURL");
        evt.setParams({
          url: editURL + "?recordId=" + recordId,
          isredirect: true
        });
      }
      evt.fire();
    } else {
      component.set("v.displayAlwaysEditForm", true);
      var spinner = component.find("spinner");
      spinner.toggle();
    }
  },

  deleteHandler: function (component, event, helper) {
    var spinner = component.find("spinner"),
      confirmParams = {
        title: "Are you sure?",
        message: "This will permenantly delete the record and can not be undone!"
      };

    helper
      .confirm(component, confirmParams)
      .then(
        $A.getCallback(function () {
          spinner.toggle();
          return helper.deleteRecord(component);
        }),
        $A.getCallback(function () {
          return Promise.reject();
        })
      )
      .then(
        $A.getCallback(function () {
          helper.returnToList(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
          spinner.toggle();
        })
      );
  },

  handleAlwayEditOnLoadAndSubmit: function (component) {
    var spinner = component.find("spinner");
    spinner.toggle();
  },

  handleAlwaysEditSuccess: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    $A.get("e.force:refreshView").fire();
  }
});
