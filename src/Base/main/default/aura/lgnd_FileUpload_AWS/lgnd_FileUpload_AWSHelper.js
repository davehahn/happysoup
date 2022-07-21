({
  initDragAndDrop: function (component) {
    var helper = this,
      dropToAWS,
      fileDataForSF = [],
      evt = component.getEvent("createSfRecordEvent"),
      lgndGallery = component.get("v.LegendGallery");

    dropToAWS = $("#dragandrophandler").legendForceDropToAWS({
      aws_FileKey: lgndGallery.s3Policy.FileKey,
      aws_Acl: lgndGallery.s3Policy.Acl,
      aws_AccessKey: lgndGallery.s3Policy.AuthKey,
      aws_Policy: lgndGallery.s3Policy.Policy,
      aws_Signature: lgndGallery.s3Policy.Signature,
      fileTypeOnly: "image",
      openFileExporerButtonId: "openFileFinder",
      uploadUrl: "https://" + lgndGallery.s3Policy.Bucket + ".s3.amazonaws.com/",
      allowDefault: component.get("v.allowDefault"),
      allowDescriptions: component.get("v.allowDescriptions"),
      fullImagePreview: component.get("v.fullImagePreview"),
      onFileChange: $A.getCallback(function (fileCount) {
        console.log("FILE COUNT IS NOW = " + fileCount);
        component.set("v.hasFiles", fileCount > 0);
      }),
      editDescriptionClickHandler: $A.getCallback(function (link) {
        var status = $(link).data("status");
        //status.descriptions.english = 'Hey this is awesome';
      }),
      onUploadComplete: $A.getCallback(function (fileName, isDefault, descriptions, imgWidth, imgHeight) {
        return new Promise(function (resolve, reject) {
          var SF_ImageData = {};
          SF_ImageData.File_Name = fileName;
          SF_ImageData.isDefault = isDefault;
          SF_ImageData.descriptions = descriptions;
          SF_ImageData.parentObjectId = lgndGallery.currentObject.Id;
          SF_ImageData.Bucket_Name = lgndGallery.s3Policy.Bucket;
          SF_ImageData.Path = lgndGallery.s3Policy.FileKey;
          SF_ImageData.Image_Width = imgWidth;
          SF_ImageData.Image_Height = imgHeight;
          fileDataForSF.push(SF_ImageData);
          resolve();
        });
      }),
      onAllComplete: $A.getCallback(function () {
        console.log("plugin all complete");
        evt.setParams({
          sfData: fileDataForSF
        });
        evt.fire();
      })
    });
    component.set("v.dropToAWS", dropToAWS);
  },

  createSalesforceRecords: function (component, sfData) {
    console.log("creating SF records");
    var action = component.get("c.createImageRecords");

    action.setParams({
      data: JSON.stringify(sfData)
    });

    action.setCallback(this, function (response) {
      console.log("done creating SF records");
      console.log(response);
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.dataForSF", []);
        var evt = $A.get("e.c:lgnd_FileUpload_AWS_Complete_Event");
        evt.fire();
      }
      if (state === "INCOMPLETE") {
        console.log("incomplete");
      }
      if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            alert("Error message: " + errors[0].message);
          }
        } else {
          alert("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  }
});
