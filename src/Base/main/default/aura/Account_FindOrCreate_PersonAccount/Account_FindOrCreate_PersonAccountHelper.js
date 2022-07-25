/**
 * Created by dave on 2020-10-02.
 */

({
  resetCustomer: function (component) {
    component.set("v.Customer", {
      id: "",
      firstName: "",
      lastName: "",
      email: "",
      phone: "",
      mobilePhone: "",
      street: "",
      city: "",
      state: "",
      stateCode: "",
      country: "",
      postalCode: ""
    });
  },

  handleCustomerSelected: function (component, objectId) {
    const spinner = component.find("spinner");

    spinner.toggle();
    this.fetchCustomer(component, objectId)
      .then(
        $A.getCallback((result) => {
          component.set("v.Customer", result);
          component.set("v.displayForm", true);
        })
      )
      .catch(
        $A.getCallback((err) => {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(() => {
          spinner.toggle();
        })
      );
  },

  fetchCustomer: function (component, objectId) {
    let action = component.get("c.fetchCustomer");
    action.setParams({
      recordId: objectId
    });
    return new LightningApex(this, action).fire();
  }
});
