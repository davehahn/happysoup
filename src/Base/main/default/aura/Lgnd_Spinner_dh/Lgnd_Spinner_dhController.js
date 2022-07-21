({
  toggle: function (component, event, helper) {
    let isVisible = component.get("v.isVisible"),
      params = event.getParam("arguments");

    helper.setBusyMessage(component, params);

    component.set("v.isVisible", !isVisible);
  },

  handleOff: function (component) {
    component.set("v.isVisible", false);
  },

  setMessage: function (component, event, helper) {
    const params = event.getParam("arguments");
    let isVisible = component.get("v.isVisible");
    helper.setBusyMessage(component, params);
    if (!isVisible) component.set("v.isVisible", true);
  }
});
