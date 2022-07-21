({
  afterScripts: function (component, event, helper) {
    console.log("details component all loaded");
    helper
      .initEventDetailsForm(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.settings", result);
          return helper.fetchRecord(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )

      .then(
        $A.getCallback(function (record) {
          console.log(record);
          component.getEvent("ModalLoaded").fire();
          if (record.startDateTime == null) record.startDateTime = component.get("v.scheduleStartDate");
          if (record.endDateTime == null) record.endDateTime = component.get("v.scheduleEndDate");
          component.set("v.eventData", record);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      );
  },

  handleCancel: function (component, event, helper) {
    console.log("close modal");
    component.getEvent("CloseModal").fire();
  },

  handleUpdate: function (component, event, helper) {
    helper.updateEventData(component, component.get("v.eventData"));
  },

  handleUnschedule: function (component, event, helper) {
    var eventData = component.get("v.eventData");
    eventData.startDateTime = "";
    helper.updateEventData(component, eventData);
  },

  handleNavToRecord: function (component, event, helper) {
    var recordId = event.currentTarget.dataset.recordId;
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt
      .setParams({
        recordId: recordId
      })
      .fire();
  }
});
