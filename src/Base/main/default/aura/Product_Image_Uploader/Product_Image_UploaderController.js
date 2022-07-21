({
  awsInitialized: function (component) {
    component.set("v.awsReady", true);
  },

  addImages: function (component) {
    component.find("fileUploader").addImages();
  },

  doUpload: function (component, event, helper) {
    component.find("fileUploader").doUpload();
  },

  imagesUploaded: function (component, event, helper) {
    component.set("v.productId", null);
    component.set("v.awsReady", false);
  }
});
