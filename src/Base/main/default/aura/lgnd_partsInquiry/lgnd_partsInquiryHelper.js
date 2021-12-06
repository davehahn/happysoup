({
	save : function(component, event) {
    console.log('partsInquiry.helper.save');
		var self = this,
				sernoName = component.get('v.sernoName'),
				model = component.get('v.ProductName'),
        description = component.get('v.description'),
        partnerReference = component.get('v.partnerReference'),
				lot = component.get('v.lot').toString();
        //isValid = self.validateDetails(component);

    console.log('partsInquiry.helper.save: vars set');

    // if (isValid) {
    // Based on feedback from that the validation is preventing
    // dealers from submitting legitimate inquiries, we will no longer
    // be validating the data.
      console.log('partsInquiry.helper.save: is valid');
      return new Promise(function(resolve, reject) {
        self.callAction(component, 'save', {
          "sernoName" : sernoName,
          "model" : model,
          "description": description,
          "partnerReference": partnerReference,
          "lot" : lot
        }).then(
          $A.getCallback(function(caseId) {
            component.set('v.caseId', caseId);
            resolve();
          }),
          $A.getCallback(function(error) {
            component.set('v.error', error[0].message);
            self.closeSpinner(component);
            reject();
          })
        );
      });
    // } else {
    //   console.log('partsInquiry.helper.save: is NOT valid');
    //   self.closeSpinner(component);
    // }
	},

	attachImages : function(component, event) {
		console.log('partsInquiry.attachImages');
    component.set('v.isUploading', true);
		var self = this;
		if (component.find('imageUploader').get('v.dropToAWS').data('pluginData').fileMap.length > 0) {
    	component.find('imageUploader').doUpload();
    } else {
      component.set('v.isUploading', false);
      window.location.replace("/s/part-inquiries/");
    }
	},

	callAction: function(component, methodName, parameters) {
    console.log('partsInquiry.helper.callAction method name:' + methodName);
    var action = component.get("c." + methodName);
    action.setParams(parameters);
    return new Promise(function(resolve, reject) {
      action.setCallback(this, function(response) {

        var responseState = response.getState();
        console.log('state: '+responseState);
        if (responseState == "SUCCESS") {
          resolve(response.getReturnValue());
        } else if (responseState === "ERROR") {
        	console.log(response.getError());
            reject(response.getError());
        } else {
          reject(responseState);
        }
      });
      $A.enqueueAction(action);
    });
  },

  openSpinner: function(component) {
  	console.log('partsInquiry.helper.openSpinner');
  	$A.util.removeClass(component.find('inquirySpinner'), 'slds-hide');
  },

  closeSpinner: function(component) {
  	console.log('partsInquiry.helper.closeSpinner');
  	$A.util.addClass(component.find('inquirySpinner'), 'slds-hide');
  },

  /* -----------------
     VALIDATION RULES
  ------------------- */

  validateDetails: function(component) {
    console.log('partsInquiry.helper.validateDetails');

    component.set('v.error','');

    var self = this,
        isValid = false;
        validSerno = self.validateSerno(component),
        validModel = self.validateModel(component),
        validYear = self.validateYear(component),
        validDescription = self.validateDescription(component);

    if (validSerno && validModel && validYear && validDescription)
      isValid = true;

    return isValid;
  },

  validateSerno: function(component) {
    console.log('partsInquiry.helper.validateSerno');
    var self = this,
        isValid = false,
        sernoName = component.get('v.sernoName'),
        error = component.get('v.error');

    if (sernoName != null && sernoName != '')
      isValid = true;
    else
      component.set('v.error', error.concat("Invalid serial number. "));

    return isValid;
  },

  validateModel: function(component) {
    console.log('partsInquiry.helper.validateModel');
    var self = this,
        isValid = false,
        model = component.get('v.ProductName'),
        error = component.get('v.error');

    if (model != null && model != '')
      isValid = true;
    else
      component.set('v.error', error.concat("Invalid product model. "));

    return isValid;
  },

  validateYear: function(component) {
    console.log('partsInquiry.helper.validateYear');
    var self = this,
        isValid = false,
        year = component.get('v.lot').toString(),
        error = component.get('v.error'),
        patt = new RegExp("[0-9]{4}");

    console.log(year);
    console.log(patt.test(year));

    if (patt.test(year)) {
      isValid = true;
    }
    else {
      component.set('v.error', error.concat("Invalid model year. "));
    }

    return isValid;
  },

  validateDescription: function(component) {
    console.log('partsInquiry.helper.validateDescription');
    var self = this,
        isValid = false,
        description = component.get('v.description'),
        error = component.get('v.error');

    if (description != null && description != '')
      isValid = true;
    else
      component.set('v.error', error.concat("Please provide a part description."));

    return isValid;
  }
})