({
  isFormValid: function( component )
  {
    return component.find('requiredField').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
  },

  caseCreateComplete: function( component )
  {
    var indicator = component.find('busy-indicator'),
        toast = $A.get("e.force:showToast"),
        utilityAPI = component.find("utilitybar");
    component.set('v.type', '');
    component.set('v.priority', '');
    component.set('v.subject', '');
    component.set('v.description', '');
    component.set('v.reason', '');
    component.set('v.formValid', false);
    $A.util.toggleClass( indicator, 'hidden' );
    toast.setParams({
      message: "Issue Logged Successfully!",
      type: "success"
    })
    .fire();
    utilityAPI.minimizeUtility();
  },

  uploadFiles: function( component )
  {
    var caseId = component.get('v.caseId'),
        isAttachmentsInitd = component.get('v.fileUploadInitd'),
        beginEvt = $A.get('e.c:lgnd_dh_fileUploadBegin_Event');

    return new Promise( function( resolve, reject ) {
      if( isAttachmentsInitd )
      {
        component.addEventHandler("c:lgnd_dh_fileUploadComplete_Event", function(auraEvent) {
          resolve();
        });
        beginEvt.setParams({
          objectId: caseId
        })
        .fire();
      }
      else
        resolve();
    });
  }

})