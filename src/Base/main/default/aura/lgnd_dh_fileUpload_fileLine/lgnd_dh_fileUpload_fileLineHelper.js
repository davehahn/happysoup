({
  CHUNK_SIZE: 750000 /* Use a multiple of 4 */,

  uploadFile: function (component, objectId) {
    var self = this,
      file = component.get("v.file"),
      fromPos = 0,
      toPos,
      fileContents,
      fr;
    component.set("v.uploadActive", true);
    return new Promise(function (resolve, reject) {
      fr = new FileReader();
      fr.onload = $A.getCallback(function () {
        fileContents = fr.result;
        var base64Mark = "base64,";
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);
        self.doUpload(component, objectId, file, fileContents, fromPos, toPos, "").then(
          $A.getCallback(function () {
            resolve();
          }),
          $A.getCallback(function (err) {
            reject(err);
          })
        );
      });

      fr.readAsDataURL(file);
    });
  },

  doUpload: function (component, objectId, file, fileContents, origFromPos, origToPos, attachId) {
    var self = this;

    return new Promise(function (resolve, reject) {
      var isChunked = false,
        uploadChunk = function (fromPos, toPos) {
          var action = component.get("c.uploadFileChunck"),
            chunk = fileContents.substring(fromPos, toPos);
          action.setParams({
            caseId: objectId,
            fileName: file.name,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId
          });

          action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
              attachId = response.getReturnValue();
              var amountComplete = Math.round((toPos / fileContents.length) * 100);
              component.set("v.amountComplete", amountComplete);
              fromPos = toPos;
              toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);

              if (fromPos < toPos) {
                isChunked = true;
                uploadChunk(fromPos, toPos);
              } else {
                if (isChunked) {
                  self.cleanUpChunckedFile(component, attachId, objectId).then(
                    $A.getCallback(function () {
                      resolve();
                    }),
                    $A.getCallback(function (err) {
                      reject(err);
                    })
                  );
                } else resolve();
              }
            } else if (state === "INCOMPLETE") {
              reject("helper line 126");
            } else if (state === "ERROR") {
              var errors = response.getError();
              if (errors) {
                if (errors[0] && errors[0].message) reject("helper line 134 " + errors[0].message); //error[0].message );
              } else {
                reject("helper line 138");
              }
            }
          });

          $A.enqueueAction(action);
        };
      uploadChunk(origFromPos, origToPos);
    });
  },

  cleanUpChunckedFile: function (component, versionId, objectId) {
    var self = this;
    return new Promise(function (resolve, reject) {
      var action = component.get("c.mergeVersions");

      action.setParams({
        versionId: versionId,
        caseId: objectId
      });

      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve();
        } else if (state === "INCOMPLETE") {
          reject("helper line 176");
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) reject("helper line 184"); //error[0].message );
          } else {
            reject("helper line 188");
          }
        }
      });

      $A.enqueueAction(action);
    });
  }
});
