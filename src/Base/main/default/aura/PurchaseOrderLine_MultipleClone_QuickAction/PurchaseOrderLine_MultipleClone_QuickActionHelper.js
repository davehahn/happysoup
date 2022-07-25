({
  closeModal: function () {
    $A.get("e.force:closeQuickAction").fire();
  },

  doClone: function (component) {
    var action = component.get("c.cloneLines");
    action.setParams({
      recordId: component.get("v.recordId"),
      lineCount: component.get("v.lineCount")
    });

    return new LightningApex(this, action).fire();
  }
});
