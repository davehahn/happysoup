({
  init: function (component) {
    var action = component.get("c.initNewService"),
      la;
    la = new LightningApex(this, action);
    return la.fire();
  },

  fetchRecord: function (component) {
    var action = component.get("c.fetchRecord"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  fetchSerialNumberDetails: function (component, serialNumberId) {
    console.log("serialNumberId = " + serialNumberId);
    if (serialNumberId === undefined || serialNumberId == null) return Promise.resolve();

    var action = component.get("c.fetchSerialDetails"),
      la;
    action.setParams({
      serialId: serialNumberId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  updateEventData: function (component, isUnscheduling) {
    var self = this;
    //    return new Promise(function(resolve, reject) {
    //      $A.util.removeClass( component.find('spinner'), 'slds-hide' );
    //      self.doUpdateEventData( component, isUnscheduling )
    //      .then(
    //        $A.getCallback( function() {
    //          LightningUtils.showToast('success', 'Success!', 'The record was successfully updated');
    //          component.getEvent("UpdateSuccess").fire();
    //          resolve();
    //        }),
    //        $A.getCallback( function(err) {
    //          $A.util.addClass( component.find('spinner'), 'slds-hide' );
    //          LightningUtils.errorToast(err);
    //          console.log( 'updateEventData ERROR:');
    //          console.log( err );
    //          reject(err);
    //        })
    //      );
    //    });
    $A.util.removeClass(component.find("spinner"), "slds-hide");
    self
      .doUpdateEventData(component, isUnscheduling)
      .then(
        $A.getCallback(function () {
          return self.updateRiggerJob(component);
        })
      )
      .then(
        $A.getCallback(function () {
          LightningUtils.showToast("success", "Success!", "The record was successfully updated");
          component.getEvent("UpdateSuccess").fire();
        })
      )
      .catch(
        $A.getCallback(function (err) {
          $A.util.addClass(component.find("spinner"), "slds-hide");
          LightningUtils.errorToast(err);
          console.log("updateEventData ERROR:");
          console.log(err);
        })
      );
  },

  doUpdateEventData: function (component, isUnscheduling) {
    var action = component.get("c.updateServiceRecord"),
      la,
      eventData = component.get("v.eventData");

    if (typeof isUnscheduling !== "undefined" && isUnscheduling) {
      eventData.startDateTime = null;
    }
    if (eventData.startDateTime === "") eventData.startDateTime = null;

    action.setParams({
      jsonEventData: JSON.stringify(eventData)
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  getRiggers: function (component) {
    var riggers = component.get("v.riggers"),
      warehouseId = component.get("v.eventData.warehouseId"),
      action = component.get("c.getRiggers"),
      la;
    component.set("v.riggers", null);
    component.set("v.riggerId", null);
    action.setParams({
      warehouseId: warehouseId
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  updateRiggerJob: function (component) {
    var erpId = component.get("v.recordId"),
      riggerId = component.get("v.riggerId"),
      action = component.get("c.updateRiggerJob");
    action.setParams({
      erpId: erpId,
      riggerId: riggerId
    });
    var la = new LightningApex(this, action);
    return la.fire();
  },

  getRiggerId: function (component) {
    var erpId = component.get("v.recordId"),
      action = component.get("c.getRiggerId"),
      la;
    action.setParams({
      erpId: erpId
    });
    la = new LightningApex(this, action);
    return la.fire();
  }
});
