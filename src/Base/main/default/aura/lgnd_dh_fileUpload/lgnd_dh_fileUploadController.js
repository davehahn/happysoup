({
  doInit: function( component )
  {
    component.set("v.fileList", []);
  },

  handleFilesChange: function( component, event, helper )
  {
    var fileList = component.get('v.fileList'),
        newFiles = event.getSource().get("v.files"),
        hasError = false,
        MAX_FILE_SIZE = 4500000, /* 6 000 000 * 3/4 to account for base64 */
        createId = function()
        {
          return Math.random().toString(36).substr(2,9);
        }

    if( fileList === null || fileList === undefined )
      fileList = [];

    for( var i=0; i<newFiles.length; i++ )
    {
      console.log( newFiles[i] );
      if( newFiles[i].size > MAX_FILE_SIZE )
        hasError = true;
      else
      {
        newFiles[i].uId = createId();
        fileList.push( newFiles[i] );
      }
    }
    component.set('v.fileList', fileList );
    if( hasError )
      component.set('v.toastContent', {'type': 'error', 'message': 'One or more files exceeded 4.5MB and was removed'});
      //alert('One or more files exceeded 4.5MB and was removed')
  },

  clearFileList: function( component )
  {
    component.set('v.fileList', []);
  },

  doFileUpload: function( component, event, helper )
  {
    var params = event.getParams();

    helper.uploadFiles( component, params.objectId )
    .then(
      $A.getCallback( function() {
        component.set('v.fileList', [] );
        var evt = $A.get('e.c:lgnd_dh_fileUploadComplete_Event');
        evt.fire();
      })
    );
  }
})