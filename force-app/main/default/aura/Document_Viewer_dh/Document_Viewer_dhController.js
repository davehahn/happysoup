({
	handleRecordUpdate : function(component, event, helper) {
    var eventParams = event.getParams();
    if(eventParams.changeType === "LOADED") {
       // record is loaded (render other component which needs record data value)
      var rec = component.get('v.record'),
           field = component.get('v.documentIdField'),
           url;
      if( rec[field] !== undefined && rec[field] !== null )
      {
        url = '/servlet/servlet.FileDownload?file=' + rec[field];
        component.set('v.docURL', url);
      }
      component.set('v.recordLoaded', true );

    } else if(eventParams.changeType === "CHANGED") {
        // record is changed
    } else if(eventParams.changeType === "REMOVED") {
        // record is deleted
    } else if(eventParams.changeType === "ERROR") {
        // there’s an error while loading, saving, or deleting the record
    }
  }
})