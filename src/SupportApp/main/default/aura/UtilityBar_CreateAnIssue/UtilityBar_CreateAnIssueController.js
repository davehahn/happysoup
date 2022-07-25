/**
 * Created by dave on 2021-07-14.
 */

({
  handleSelected: function (component, event, helper) {
    console.log("I got the selected event");
    var utilityAPI = component.find("utilityBarAPI");
    utilityAPI.minimizeUtility();
  }
});
