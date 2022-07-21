({
  doInit: function (component, event, helper) {
    var spinner = component.find("spinner");
    spinner.toggle();
    helper
      .searchInventories(component)
      .then(
        $A.getCallback(function (result) {
          console.log(result);
          component.set("v.regsByBoat", result.inventory);
          component.set("v.boatSelectOpts", result.boatSelectOptions);
        }),
        $A.getCallback(function (err) {
          LightningUtils.errorToast(err);
        })
      )
      .finally(
        $A.getCallback(function () {
          spinner.toggle();
        })
      );
  },

  handleBoatChange: function (component, event) {
    var regsByBoat = component.get("v.regsByBoat"),
      boat = event.getSource().get("v.value");

    if (boat != null && boat.length > 0) component.set("v.dealers", regsByBoat[boat]);
    else component.set("v.dealers", []);
  }
});
