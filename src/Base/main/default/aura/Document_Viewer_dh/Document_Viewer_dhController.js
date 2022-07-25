({
  doInit: function (component) {
    component.set("v.scriptsLoaded", true);
  },

  handleRecordUpdate: function (component, event, helper) {
    var eventParams = event.getParams();
    if (eventParams.changeType === "LOADED") {
      // record is loaded (render other component which needs record data value)
      helper.handleRecordLoaded(component);
    } else if (eventParams.changeType === "CHANGED") {
      // record is changed
    } else if (eventParams.changeType === "REMOVED") {
      // record is deleted
    } else if (eventParams.changeType === "ERROR") {
      // there’s an error while loading, saving, or deleting the record
    }
  },

  checkToInit: function (component, event, helper) {
    const recordLoaded = component.get("v.recordLoaded"),
      scriptsLoaded = component.get("v.scriptsLoaded");

    if (!recordLoaded || !scriptsLoaded) return;

    helper
      .fetchAllDocuments(component)
      .then(
        $A.getCallback(function (result) {
          console.log(JSON.parse(JSON.stringify(result)));
          component.set("v.erpDocuments", result);
          component.set("v.initialized", true);
        })
      )
      .catch(
        $A.getCallback(function (err) {
          LightningUtils.ErrorToast(err);
        })
      );
  },

  handlePdfSelect: function (component, event, helper) {
    let docId = event.getSource().get("v.value");
    console.log(`Document Id = ${docId}`);
    component.set("v.activeDocId", docId);
    let url = "/servlet/servlet.FileDownload?file=" + docId;
    component.set("v.docURL", url);
  }
});
