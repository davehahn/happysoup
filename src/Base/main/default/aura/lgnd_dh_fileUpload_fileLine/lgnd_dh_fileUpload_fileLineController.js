({
  doUpload: function (component, event, helper) {
    var objectId = event.getParam("arguments").objectId;
    console.log("lgnd_dh_fileUpload_fileLine.doUpload ");
    console.log(objectId);
    helper.uploadFile(component, objectId).then(
      $A.getCallback(function () {
        var evt = $A.get("e.c:lgnd_dh_fileUpload_fileLine_Complete_Event");
        evt.fire();
      }),
      $A.getCallback(function (err) {
        alert(err);
      })
    );
  }
});
