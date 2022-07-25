({
  CHUNK_SIZE: 750000 /* Use a multiple of 4 */,

  uploadFiles: function (component, objectId) {
    var self = this,
      fileCmps = component.find("file--CMP");
    //fileList = component.get('v.fileList');

    if (fileCmps === null || fileCmps === undefined) fileCmps = [];

    if (fileCmps.length === undefined) fileCmps = [fileCmps];

    // if( $A.util.isEmpty( fileList ) )
    //   return Promise.resolve();

    return fileCmps.reduce(function (p, cmp) {
      return p.then(
        $A.getCallback(function () {
          return self.uploadFile(component, cmp, objectId);
        })
      );
    }, Promise.resolve());
  },

  uploadFile: function (component, fileCmp, objectId) {
    return new Promise(function (resolve, reject) {
      component.addEventHandler("c:lgnd_dh_fileUpload_fileLine_Complete_Event", function (auraEvent) {
        resolve();
      });
      fileCmp.doUpload(objectId);
    });
  }
});
