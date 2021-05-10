({
	doInit : function(component, event, helper) {
		component.find('spinner').toggle();
		helper.getClaimDetails(component, event)
		.then(
			$A.getCallback( function(result) {
    		component.set('v.claim', result);
        component.set('v.regId', result.Registration__c);
    		switch(result.Status) {
    			case 'Pending registration':
    				component.set('v.stage', 1);
    				break;
          case 'Pending documentation':
            component.set('v.stage', 2);
            break;
    			case 'Pending review':
    				component.set('v.stage', 3);
    				break;
    			case 'Pending payout':
    				component.set('v.stage', 4);
    				break;
    			case 'Complete':
    				component.set('v.stage', 5);
    				break;
    			default:
    				component.set('v.stage', 0);
    		}
        if (result.Promotion_Item__r !== undefined) {
          if (result.Promotion_Item__r.Promotion__r !== undefined) {
        		if (result.Promotion_Item__r.Promotion__r.Document_Requirements__c !== undefined) {
          		var reqs = result.Promotion_Item__r.Promotion__r.Document_Requirements__c.split(';');
            	component.set('v.requirements', reqs);
            	component.set('v.AccountId', result.Promotion_Customer_Account__c);
            }
          }
        }
    		component.set('v.done', true);
				component.find('spinner').toggle();
			}),
			$A.getCallback( function(err) {
    		component.set('v.done', true);
				component.find('spinner').toggle();
			})
		);
	},

	goToStep2 : function(component, event, helper) {
		component.set('v.stage', 2);
	},

	goToStep3 : function(component, event, helper) {
		component.find('spinner').toggle();
		helper.claimPromotion(component);
	},

  handleUploadFinished : function(component, event) {
    var files = component.get('v.files'),
    		uploadedFiles = event.getParam("files");

    for (var i = 0; i < uploadedFiles.length; i++) {
    	files.push(uploadedFiles[0]);
    }
    component.set('v.files',files);
  },

  openRegistrationForm : function(component, event) {
  	component.set('v.regInProcess', true);
  	return false;
  }
})