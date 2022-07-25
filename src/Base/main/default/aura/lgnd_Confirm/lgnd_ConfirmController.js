({
  showConfirm: function (component, event, helper) {
    var params = event.getParam("arguments").confirmParams;
    helper.toggleModal(component, params.title, params.message);
  },

  respondNo: function (component, event, helper) {
    helper.handleRespond(component, false);
  },

  respondYes: function (component, event, helper) {
    helper.handleRespond(component, true);
  }
});
