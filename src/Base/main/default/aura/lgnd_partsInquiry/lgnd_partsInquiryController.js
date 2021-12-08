({
	doInit : function(component, event, helper) {
	},

	next: function(component, event, helper) {
    console.log('partsInquiry.next');
    var step = component.get('v.onStep'),
    isUploading = component.get('v.isUploading');
    if( isUploading )
      return false;

    component.set('v.error','');

    helper.openSpinner(component);
    helper.save(component, event)
    			.then(function() {

            component.set('v.parentId', component.get('v.caseId'));
            component.find('imageUploader').initWithId(component.get('v.parentId'));
            step++;
            component.set('v.onStep', step);
            helper.closeSpinner(component);
    			});
  },

  done: function(component, event, helper) {
    helper.openSpinner(component);
		helper.attachImages(component, event);
  },
  validateSerialNo: function (cmp, event) {

      if(cmp.get('v.sernoName') == null || cmp.get('v.sernoName')=='')
        cmp.set('v.stepOneValid', true);
      else
        cmp.set('v.stepOneValid', false);
  },

  imagesUploaded: function(component, event, helper) {
    component.set('v.isUploading', false);
    console.log('partsInquiry.imagesUploaded');
    // var onStep = component.get('v.onStep');
    // onStep++;
    // component.set('v.onStep', onStep);
    window.location.replace("/s/part-inquiries/");
    // helper.closeSpinner(component);
  }
})