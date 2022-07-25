/**
 * Created by dave on 2020-02-10.
 */

({
  doInit: function (component, event, helper) {
    console.log("commissionCalculator2.doInit");
    helper.getRecords(component).then(
      $A.getCallback(function (result) {
        component.set("v.commissionRecords", result);
      }),
      $A.getCallback(function (err) {
        LightningUtils.errorToast(err);
      })
    );
  },

  handleRecordChange: function (component, event) {
    var record = event.getParam("record");
    component.set("v.selectedRecord", record);
  }
});
