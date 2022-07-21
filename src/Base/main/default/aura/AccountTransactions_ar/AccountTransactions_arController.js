({
  doInit: function (component, event, helper) {
    helper.toggleSpinner(component, true);
    helper.retrieveAccountTransactions(component, event, helper);
  },
  retrieveAccountBillings: function (component, event, helper) {
    helper.retrieveAccountTransactions(component, event, helper);
  },
  removeComponent: function (component) {
    component.destroy();
  }
});
