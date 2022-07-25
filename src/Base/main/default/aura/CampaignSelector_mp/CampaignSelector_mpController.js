({
  afterScripts: function (component, event, helper) {
    helper.initialize(component);
  },

  selectCampaign: function (component, event, helper) {
    var value = component.find("campaignSelect").get("v.value");
    component.set("v.campaign", value);
  }
});
