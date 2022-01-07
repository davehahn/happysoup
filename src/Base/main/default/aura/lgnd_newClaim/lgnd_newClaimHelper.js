({
  doStep: function(component, event) {
    var step = component.get('v.onStep'),
        self = this,
        initialized = component.get('v.uploaderInitialized');
    return new Promise(
      function(resolve, reject) {
        if (step == 1) {
         // component.set('v.disableNextButton', true);
          self.doStepOne(component, event)
          .then(
            function() {

              component.set('v.disableNextButton', false);
              resolve();
            }
          );
        } else if (step == 2) {
         // component.set('v.disableNextButton', true);
          self.doStepTwo(component, event)
          .then(
            function() {
              component.set('v.disableNextButton', false);
              resolve();
            }
          );
        } else if (step == 3) {
          component.set('v.disableNextButton', false);
          self.doStepThree(component, event)
          .then(
            function() {
              resolve();
            }
          );
        }else if (step == 4) {
          if (!initialized) {
            component.set('v.disableNextButton', true);
          } else {
            component.set('v.disableNextButton', false);
          }
          self.doStepFour(component, event)
          .then(
            function() {
              resolve();
            }
          );
        } else if (step == 5) {
          component.set('v.disableNextButton', true);
          self.doStepFive(component, event)
          .then(
            function() {
              component.set('v.disableNextButton', false);
              resolve(); }
          );
        } else {
          reject();
        }
      }
    );
  },

  doStepOne: function(component, event) {

    var serialLookupComponent = component.find("sernoSearch"),
        failDate = component.get("v.claim.case.Date_Failure__c"),
        today = new Date(),
        claim = component.get('v.claim');

    return new Promise(
      function(resolve, reject) {

        if (!serialLookupComponent.get("v.sernoId")) {
          component.set("v.error", "Serial number is required.");
          $A.util.addClass(component.find('spinner'), 'slds-hide');
          reject();
        } else if (!failDate) {
          component.set("v.error", "When did the damage occur?");
          $A.util.addClass(component.find('spinner'), 'slds-hide');
          reject();
        } else if (Date.parse(failDate) > today) {
          component.set("v.error", "Are you from the future?! Please pick a date in the past.");
          $A.util.addClass(component.find('spinner'), 'slds-hide');
          reject();
        } else {
          serialLookupComponent.set("v.error", null);
          component.set("v.isValid", true);

          if (claim.uid === undefined) {
            claim.uid = Math.floor((Math.random() * 100000) + 1);
          }
          claim.case.Serial_Number__c = component.get('v.sernoId');
          claim.case.Customer_Name__c = component.get('v.accountName');
          claim.case.Serial_Number_Registered_To__c = component.get('v.accountId');
          console.log('claim= '+claim);
          component.set('v.claim', claim);
        }

        $A.util.addClass(component.find('spinner'), 'slds-hide');

        resolve();
      }
    );
  },

  doStepTwo: function(component, event) {
    var self = this,
        problem = component.get('v.claim.case.Description'),
        type = component.get('v.claim.case.Claim_Type__c'),
        correction = component.get('v.claim.case.Correction__c'),
        hours = component.get('v.claim.case.Labor_Hours__c'),
        laborPrice = component.get('v.laborUnitCost'),
        productId = component.get('v.productId');
    return new Promise(
      function(resolve, reject) {

        if (!problem || !type || !correction) {
          component.set("v.error", "A required field was missed.");
          reject();
        } else {

          if (hours > 0 && !component.get('v.labourAdded')) {


            self.callAction(component, 'getProduct', {
              "id" : productId
            }).then(
              $A.getCallback( function(product) {
                var parts = component.get("v.parts");
                for (var i = 0; i < parts.length; i++) {
                  if (parts[i].Product__c == product.Id) {
                    parts.splice(i, 1);
                  }
                }
                console.log(`Labor Price = ${laborPrice}`);
                parts.push({
                  sobjectType: "Case_Part__c",
                  Case__c: undefined,
                  Product__c: product.Id,
                  Product__r: product,
                  Quantity__c: hours,
                  Unit_Price__c: laborPrice
                });
                component.set('v.labourAdded',true);
                component.set("v.parts", parts);
              })
            );
          }
        }
        $A.util.addClass(component.find('spinner'), 'slds-hide');
        resolve();
      }
    );
  },

  doStepThree: function(component, event) {
    var self = this,
        onStep = component.get('v.onStep');

    return new Promise(function(resolve, reject) {
      $A.util.addClass(component.find('spinner'), 'slds-hide');
      resolve();
    });
  },

  doStepFour: function(component, event) {
    var self = this,
        onStep = component.get('v.onStep');

    return new Promise(
      function(resolve, reject) {
        $A.util.addClass(component.find('spinner'), 'slds-hide');

        self.saveProblem(component, event)
        .then(
          $A.getCallback( function() {
            var claims = component.get("v.claims"),
                claim = component.get("v.claim"),
                claimPosition = component.get('v.claimPosition');

            claim.Customer_Name__c = component.get('v.accountName');
            claim.Status = 'saved';
            claim.parts = component.get('v.parts');

            for (var i = 0; i < claims.length; i++) {
              if (claims[i].uid === claim.uid) {
                claims.splice(i, 1);
              }
            }
            claims.push(claim);
            component.set('v.claims', claims);

            claimPosition++;
            component.set('v.claimPosition');

            $A.util.addClass(component.find('spinner'), 'slds-hide');
            self.createUploader(component)
            .then(
              $A.getCallback( function() {
                resolve();
              }),
              $A.getCallback( function() {
                resolve();
              })
            );
          }),
          $A.getCallback( function(e) {
            $A.util.addClass(component.find('spinner'), 'slds-hide');
            self.showToast( e, 'error' );
            reject();
          })
        );
      }
    );
  },

  createUploader: function(component) {
    var self = this,
        imageUploaderContainer = component.find('imageUploaderContainer');

    return new Promise(function(resolve, reject) {
      if (imageUploaderContainer.get('v.body') == '') {
        $A.createComponent(
          "c:lgnd_FileUpload_AWS",
          {
            "recordId" : component.get('v.parentId'),
            "aura:id" : "imageUploader"
          },
          function( uploader, status, message )
          {
            if (status === "SUCCESS") {
              var body = imageUploaderContainer.get('v.body');
              body.push(uploader);
              imageUploaderContainer.set('v.body', body);
              component.addEventHandler('c:lgnd_FileUpload_AWS_Initialized_Event', function(auraEvent) {
                component.set('v.uploaderInitialized', true);
                component.set('v.disableNextButton', false);
              });
            } else if (status === "INCOMPLETE") {
              console.log('No response from server or client is offline.');
            } else if (status === "ERROR") {
              console.log('Error: ' + message);
            }
          }
        );
      }
      resolve();
    });
  },

  doStepFive: function(component, event) {
    return new Promise(
      function(resolve, reject) {
        if (component.find('imageUploader').get('v.dropToAWS').data('pluginData').fileMap.length > 0) {
          component.find('imageUploader').doUpload();
        } else {
          $A.util.addClass(component.find('spinner'), 'slds-hide');
        }
        resolve();
      }
    );
  },

  saveProblem: function(component, event) {
    var self = this,
        spinner = component.find('spinner');

    $A.util.removeClass(spinner, 'slds-hide');

    if (!self.validateProblem(component)) {
      $A.util.addClass(spinner, 'slds-hide');
      return false;
    }

    return new Promise(function(resolve, reject) {
      self.createClaim(component)
      .then(
        $A.getCallback( function() {
          resolve();
        }),
        $A.getCallback( function(err) {
          reject(err);
        })
      );
    });
  },

  updateClaims: function(component, event) {
    $A.util.removeClass(component.find('spinner'), 'slds-hide');

    var self = this,
        claims = component.get('v.claims'),
        i = 0;



    return new Promise(function(resolve, reject) {
      for (var claim in claims) {
        self.updateClaim(component, claim)
        .then(
          $A.getCallback( function() {
            i++;
            if (i == claims.length) {
              resolve();
            }
          })
        );
      }
    });
  },

  updateClaim: function(component, claim) {
    var self = this;
    return new Promise(function(resolve, reject) {
      self.callAction(component, "saveWithParts", {
            "caseJson": JSON.stringify(claim.case),
            "caseParts": claim.parts
          })
          .then(
            $A.getCallback(function(caseId) {
              resolve();
            }),
            $A.getCallback(function(err) {
              console.log(err);
            })
          );
    });
  },

  deletePart: function(component,event) {
    var partsIndex = event.currentTarget.getAttribute("data-parts-index");
    var parts = component.get("v.parts");
    var part = parts[partsIndex];
    if(part.Id != undefined || part.Id != null){
      var self = this;
      return new Promise(function(resolve, reject) {
        self.callAction(component, "deletePartById", {
              "idPart": part.Id
            })
            .then(
              $A.getCallback(function(result) {
                parts.splice(partsIndex, 1);
                component.set("v.parts", parts);

                resolve();
              }),
              $A.getCallback(function(err) {
                console.log(err);
                reject(err);
              })
            );
      });
    }else{
      parts.splice(partsIndex, 1);
      component.set("v.parts", parts);
    }
  },
  updateWholesaleLabour: function(component,event) {

      var parts = component.get("v.parts");
      var self = this;
      if(parts.length >0){
        var part;
        var hours = component.get('v.claim.case.Labor_Hours__c');

          	for (i = 0; i < parts.length; i++) {
          		if(parts[i].Product__c == component.get("v.productId")){

                    console.log("parts json= "+JSON.stringify(parts[i]));
                    parts[i].Quantity__c = hours;
                    if(hours > 0){
						if(parts[i].Id != undefined){

							return new Promise(function(resolve, reject) {
							self.callAction(component, "updatePartById", {
								  "idPart": parts[i].Id,
								  "qty": hours
								})
								.then(
								  $A.getCallback(function(result) {
									component.set("v.parts", parts);
        							resolve();
								  }),
								  $A.getCallback(function(err) {
									console.log(err);
									reject(err);
								  })
								);
						  });

						}
					}else{

						return new Promise(function(resolve, reject) {
							self.callAction(component, "deletePartById", {
							"idPart": parts[i].Id
						})
						.then(
							  $A.getCallback(function(result) {
								parts.splice(i, 1);
								component.set("v.parts", parts);
								component.set("v.labourAdded", false);
								resolve();
							  }),
							  $A.getCallback(function(err) {
								console.log(err);
								reject(err);
							  })
							);
						});
					}

                    break;
          		}
      		}
            component.set("v.parts",parts);

      }

    },

  getParts: function(component) {
    var self = this,
        claim = component.get('v.claim');
    return new Promise(function(resolve, reject) {
      self.callAction(component, "getPartByCaseId", {
            "caseId": claim.case.Id
          })
          .then(
            $A.getCallback(function(result) {
              component.set('v.parts', result);
              resolve();
            }),
            $A.getCallback(function(err) {
              console.log(err);
              reject(err);
            })
          );
    });
  },

  validateProblem: function(component) {
    var isValid = false,
      index = component.get('v.onProblemNum'),
      description = component.get('v.claim.case.Description'),
      correction = component.get('v.claim.case.Correction__c'),
      claimType = component.get('v.claim.case.Claim_Type__c');

    // validate description
    if (!description) {
      component.find("description").set("v.errors", [{ message: "Description is required" }]);
      return false;
    } else {
      component.find("description").set("v.errors", null);
    }

    // validate correction
    if (!correction) {
      component.find("correction").set("v.errors", [{ message: "Correction is required" }]);
      return false;
    } else {
      component.find("correction").set("v.errors", null);
    }

    // validate claim type
    if (!claimType) {
      alert('Select a type of problem, you must.');
      return false;
    }

    // validate sublet
    if (component.get("v.showSublet")) {
      var subletCompanyComponent = component.find("subletCompany"),
          subletPriceComponent = component.find("subletPrice");

      if (subletCompanyComponent.length > 1)
        subletCompanyComponent = subletCompanyComponent[subletCompanyComponent.length -1];

      if (subletPriceComponent.length > 1)
        subletPriceComponent = subletPriceComponent[subletPriceComponent.length -1];

      // validate sublet company
      if (!component.get("v.claim.case.Sublet_Company__c")) {
        subletCompanyComponent.set("v.errors", [{ message: "Sublet company is required" }]);
        return false;
      } else {
        subletCompanyComponent.set("v.errors", null);
      }

      // validate sublet price
      if (!component.get("v.claim.case.Sublet_Price__c")) {
        subletPriceComponent.set("v.errors", [{ message: "Sublet price is required" }]);
        return false;
      } else {
        subletPriceComponent.set("v.errors", null);
      }
    }

    return true;
  },

  createClaim: function(component) {
    var self = this,
        claim = component.get('v.claim');

    return new Promise(function(resolve, reject) {
      self.callAction(component, "saveWithParts", {
        "caseJson": JSON.stringify(claim.case),
        "caseParts": component.get('v.parts')
      })
      .then(
        $A.getCallback(function(caseId) {
          component.set('v.claim.case.Id', caseId);
          component.set('v.parts', []);
          component.set('v.parentId', caseId);
          resolve();
        }),
        $A.getCallback(function(err) {
          reject(err);
        })
      );
    });
  },

  addSubletAttachment: function(component, event) {
    var caseId = event.target.dataset.parent,
        beginEvt = $A.get('e.c:lgnd_dh_fileUploadBegin_Event');

    $A.util.removeClass(component.find('spinner'), 'slds-hide');

    return new Promise( function( resolve, reject ) {
      component.addEventHandler("c:lgnd_dh_fileUploadComplete_Event", function(auraEvent) {
        $A.util.addClass(component.find('spinner'), 'slds-hide');
        resolve();
      });
      beginEvt.setParams({
        objectId: caseId
      })
      .fire();
    });
  },

  getProduct: function(component, productId) {
    return this.callAction(component, "getProduct", { "id": productId });
  },

  removeClaims: function(component) {
    var self = this,
        claims = component.get('v.claims'),
        claimIds = [];

    for (i = 0; i < claims.length; i++) {
      claimIds.push(claims[i].case.Id);
    }

    return new Promise(function(resolve, reject) {
      self.callAction(component, "deleteClaims", {"claimIds": claimIds})
      .then(
        $A.getCallback( function() {
          resolve();
        })
      );
    });
  },

  removeClaim: function(component) {

    var self = this,
        claims = component.get('v.claims'),
        claim = component.get('v.claim'),
        onStep = component.get('v.onStep'),
        claimIds = [];

    if (onStep < 3) {
      claims.pop();
      component.set('v.claims', claims);
    } else {
      claimIds.push(claim.case.Id);
      return new Promise(function(resolve, reject) {
        self.callAction(component, "deleteClaims", {"claimIds": claimIds})
        .then(
          $A.getCallback( function() {
            claims.pop();
            component.set('v.claims', claims);
            claim = claims[claims.length-1];
            component.set('v.claim', claim);
            resolve();
          })
        );
      });
    }
  },

  getUnitPrice: function(component, productId) {
    var self = this;
    return new Promise(function(resolve, reject) {
      self.callAction(component, 'getUnitPrice', {
        "productId": productId
      })
      .then(
        $A.getCallback( function(unitPrice) {
          resolve(unitPrice);
        })
      );
    });
  },

  callAction: function(component, methodName, parameters) {
    var action = component.get("c." + methodName);
    action.setParams(parameters);
    return new Promise(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var responseState = response.getState();
        if (responseState == "SUCCESS") {
          resolve(response.getReturnValue());
        }
        else if (responseState === "ERROR")
        {
          var errors = response.getError();
          if (errors)
          {
            if (errors[0] && errors[0].message)
            {
              reject( errors[0].message);
            }
            if( errors[0] && errors[0].pageErrors && errors[0].pageErrors.length > 0 )
            {
              reject( errors[0].pageErrors[0].message );
            }
          }
        }
        else {
          reject(responseState);
        }
      });
      $A.enqueueAction(action);
    });
  },

  showToast: function( message, messageType )
  {
    var toast = $A.get('e.force:showToast');
    toast.setParams({
      message: message,
      type: messageType
    })
    .fire();
  }
})