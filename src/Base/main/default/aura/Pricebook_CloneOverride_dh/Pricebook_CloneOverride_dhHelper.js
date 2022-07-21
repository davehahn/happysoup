({
  fetchPricebook: function (component) {
    var action = component.get("c.fetchPricebook"),
      la;
    action.setParams({
      recordId: component.get("v.recordId")
    });
    la = new LightningApex(this, action);
    return la.fire();
  },

  closeModal: function (component) {
    component.set("v.origPricebookName", null);
    component.set("v.modalOpen", false);
    component.set("v.cloneEntriesAsWell", false);
    component.set("v.cloneFeesAsWell", false);
    component.set("v.cloneUpgradesAsWell", false);
  },

  doClone: function (component) {
    var action = component.get("c.clonePricebook"),
      la,
      params = {
        origPbId: component.get("v.recordId"),
        pricebook: component.get("v.pricebook"),
        includeEntries: component.get("v.cloneEntriesAsWell"),
        includeFees: component.get("v.cloneFeesAsWell"),
        includeUpgrades: component.get("v.cloneUpgradesAsWell")
      };
    console.log(params);
    action.setParams(params);
    la = new LightningApex(this, action);
    return la.fire();
  },

  successToastMessage: function (component) {
    var title,
      message = "",
      entries = component.get("v.cloneEntriesAsWell"),
      fees = component.get("v.cloneFeesAsWell"),
      upgrades = component.get("v.cloneUpgradesAsWell");

    title = "Success! Pricebook cloned.";
    if (entries != true && fees != true && upgrades != true) {
      message = "Pricebook successfully cloned";
    } else {
      title += "\nInitiated cloning of";
      message = "";
      if (entries) {
        message = "You will be notified when cloning entries is complete.";
        title += " entries,";
      }
      if (fees) {
        if (message.length > 0) message += "\n";
        message += "You will be notified when cloning fees is complete.";
        title += " fees,";
      }
      if (upgrades) {
        if (message.length > 0) message += "\n";
        message += "You will be notified when cloning upgrades is complete.";
        title += " upgrades,";
      }
      title = title.slice(0, -1);
      var lastComma = title.lastIndexOf(",");
      if (lastComma > 0) title = title.substring(0, lastComma) + " and" + title.substring(lastComma + 1);
      title += "....";
    }
    LightningUtils.showToast("success", title, message);
  }
});
