({
  handleRecordLoaded: function (component) {
    var self = this,
      rec = component.get("v.record"),
      field = component.get("v.documentIdField"),
      url;
    if (rec[field] !== undefined && rec[field] !== null) {
      component.set("v.activeDocId", rec[field]);
      url = "/servlet/servlet.FileDownload?file=" + rec[field];
      component.set("v.docURL", url);
    }
    component.set("v.recordLoaded", true);
    //    self.fetchAllDocuments( component )
    //    .then(
    //      $A.getCallback( function( result ){
    //        console.log( JSON.parse(JSON.stringify(result)));
    //
    //      })
    //    )
    //    .catch(
    //      $A.getCallback( function(err) {
    //        LightningUtils.errorToast( err );
    //      })
    //    );
  },

  fetchAllDocuments: function (component) {
    let action = component.get("c.fetchErpDocuments");
    action.setParams({
      recordId: component.get("v.recordId")
    });
    return new LightningApex(this, action).fire();
  }
});
