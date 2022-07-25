({
  autoInit: function (component, event, helper) {
    if (component.get("v.autoInit")) {
      helper.doInit(component);
    }
  },

  manualInit: function (component, event, helper) {
    helper.doInit(component);
  },

  prevImage: function (component, event, helper) {
    var images = component.get("v.imageList"),
      currentNum = component.get("v.currentImageNum") - 1;
    component.set("v.currentImage", images[currentNum]);
    component.set("v.currentImageNum", currentNum);
  },

  nextImage: function (component, event, helper) {
    var images = component.get("v.imageList"),
      currentNum = component.get("v.currentImageNum") + 1;
    component.set("v.currentImage", images[currentNum]);
    component.set("v.currentImageNum", currentNum);
  },

  viewImage: function (component, event, helper) {
    //component.set('v.viewImage', true);
    var viewer = component.find("image-viewer"),
      currentImage = component.get("v.currentImage"),
      viewerEle,
      container,
      img;

    $A.util.addClass(viewer, "open");
    setTimeout(function () {
      viewerEle = viewer.getElement();
      container = component.find("image-viewer-container").getElement();
      container.style.height = viewerEle.offsetHeight * 0.9 + "px";
      container.style.marginTop = viewerEle.offsetHeight * 0.05 + "px";
      img = document.createElement("IMG");
      img.onload = function () {
        $A.util.addClass(viewerEle, "loaded");
      };
      img.setAttribute("src", currentImage.URL_Original);
      container.appendChild(img);
    }, 300);
  },

  closeViewer: function (component, event, helper) {
    //component.set('v.viewImage', false );
    var viewer = component.find("image-viewer"),
      container = component.find("image-viewer-container").getElement();
    $A.util.removeClass(viewer, "open");
    $A.util.removeClass(viewer, "loaded");
    container.innerHTML = "";
  },

  doUpload: function (component, event, helper) {
    var awsCmp = component.find("aws-CMP"),
      fileCount = awsCmp.get("v.dropToAWS").data("pluginData").fileMap.length;
    if (fileCount > 0) awsCmp.doUpload();
    else return false;
  },

  imagesUploaded: function (component, event, helper) {
    console.log("image up[loaded");
    helper.doInit(component);
  }
});
