({
  doInit: function (component, event, helper) {
    component.set("v.isLoading", true);
    component.set("v.options", null);
    helper.setStandardProductId(component);
    helper
      .fetchOptions(component)
      .then(
        $A.getCallback(function (result) {
          component.set("v.options", result);
          helper.setSelected(component);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          component.set("v.isLoading", false);
        })
      );
  },

  toggleDetails: function (component, event, helper) {
    component.set("v.showDetails", !component.get("v.showDetails"));
  },

  handleValueChange: function (component, event, helper) {
    const valueId = component.get('v.valueId');
    const originalValueId = component.get('v.originalValueId');
    console.log(`valueId = ${valueId}, originalValueId = ${originalValueId}`);
    console.log( JSON.parse( JSON.stringify( event.getParams() ) ) );
    helper.removeSelectedOptions(component).then(
      $A.getCallback(function () {
        helper.setSelected(component);
      })
    );
  }
});
