({
  doInit: function( component, event, helper )
  {
    var action = component.get('c.initForm');
    new LightningApex( helper, action ).fire()
    .then(
      $A.getCallback( result => {
        console.log('INIT FORM RESULT');
        console.log( JSON.parse(JSON.stringify(result)));
        component.set( 'v.productId', result.warrantyLabourProduct );
        component.set( 'v.pricebookId', result.pricebookId );
        component.set( 'v.laborUnitCost', result.laborPrice );
        component.set( 'v.claimTypeOptions', result.claimTypeOptions );
        component.set('v.claim', {
          'case': { 'sobjectType': 'Case' },
          'parts': [],
          'isValid': false,
          'imagesAdded': false
        });
      })
    )
    .catch( err => {
      LightningUtils.errorToast( err );
    });
  },

  next: function(component, event, helper) {
    console.log('newClaim.next');
    var onStep = component.get('v.onStep'),
        isValid,
        self = this;

    component.set('v.error',null);

    $A.util.removeClass(component.find('spinner'), 'slds-hide'); 

    helper.doStep(component, event).then(
      function() {
        isValid = component.get('v.isValid');
        console.log(isValid);
        if (isValid) {
          onStep++;
          component.set('v.onStep', onStep);
        }
      }
    ); 
  },

  back: function(component, event, helper) {
    console.log('newClaim.back');
    console.log(component.get('v.claim'));
    var onStep = component.get('v.onStep'),
        imageUploaderContainer = component.find('imageUploaderContainer');
    onStep--;
    console.log('newClaim.back: Step: ' + onStep);
    new Promise(function(resolve, reject) {
      if (onStep == 5) {
        imageUploaderContainer.set('v.body', '');
        helper.doStepFour(component, event);
        resolve();
      } else if (onStep == 4) {
        component.set('v.disableNextButton', false);
        helper.getParts(component)
        .then(
          $A.getCallback( function() {
            resolve();
          }),
          $A.getCallback( function(err) {
            reject(err);
          })
        );
      //} else if (onStep == 2) {
      } else {
        component.set('v.disableNextButton', false);
        resolve();
      }
    })
    .then( function() {
      component.set('v.onStep', onStep);
    });
  },

  cancel: function(component, event, helper) {
    console.log('newClaim.cancel');

    var confirmParams = {
          title: "Are you sure?",
          message: "You will lose all information entered so far.",
          state: 'error'
        },
        confirmCmp = component.find('lgnd-confirm');

    return new Promise( function( resolve, reject ) {
      component.addEventHandler('c:lgnd_Confirm_Response_Event', function( auraEvent ) {
        auraEvent.getParam('theResponse') ? resolve() : reject();
      });
      confirmCmp.showConfirm( confirmParams );
    })
    .then(
      $A.getCallback( function() {
        var onStep = component.get('v.onStep'),
            claims = component.get('v.claims'),
            claim = component.get('v.claim');

        console.log(claims);

        $A.util.removeClass(component.find('spinner'), 'slds-hide');

        if (claims.length < 1) {
          helper.removeClaims(component)
          .then(
            $A.getCallback( function() {
              onStep = 1;
              component.set('v.onStep', onStep);
              window.location.replace("/s/case/Case/Recent");
            })
          );
        } else if (onStep < 5) {
          helper.removeClaims(component)
          .then(
            $A.getCallback( function() {
              claim = claims[claims.length-1];
              component.set('v.claim', claim);
              onStep = 6;
              component.set('v.onStep', onStep);
              $A.util.addClass(component.find('spinner'), 'slds-hide');
            })
          );
        } else {
          helper.removeClaim(component)
          .then(
            $A.getCallback( function() {
              onStep = 6;
              component.set('v.onStep', onStep);
              $A.util.addClass(component.find('spinner'), 'slds-hide');
            })
          );
        }
      }),
      $A.getCallback( function( err ){
        // Do nothing.
      })
    );
  },

  addProblem: function(component, event, helper) {
    console.log('newClaim.addProblem');
    var onStep = component.get('v.onStep'),
        claim = component.get('v.claim'),
        newClaim = {
          'case': {
            'sobjectType': 'Case',
            'parts': [],
            'Serial_Number__c': claim.case.Serial_Number__c,
            'Partner_Reference__c': claim.case.Partner_Reference__c
          },
          'parts': [],
          'isValid': false
        };

    helper.saveProblem(component, event).then(
      $A.getCallback( function() {
  	    component.set("v.claim", newClaim);
        component.set("v.parts", []);
        component.set("v.showSublet", false);
        console.log(component.get("v.showSublet"));
  	    onStep = 2;
  	    component.set('v.onStep', onStep);
  	    $A.util.addClass(component.find('spinner'), 'slds-hide');
      }),
      $A.getCallback( function( err ){
        $A.util.addClass(component.find('spinner'), 'slds-hide');
        helper.showToast( err, 'error' );
      })
    );
  },

  submit: function(component, event, helper) {
    console.log('newClaim.submit');
    helper.updateClaims(component, event)
    .then(
      $A.getCallback( function() {
    	  console.log('submitted');
        window.location.replace("/s/case/Case/Recent");
      })
    )
  },

  imagesUploaded: function(component, event, helper) {
    console.log('lgnd_newClaim: imagesUploaded');
    var onStep = component.get('v.onStep'),
        claims = component.get('v.claims'),
        imageUploaderContainer = component.find('imageUploaderContainer');
    imageUploaderContainer.set('v.body', '');
    component.set('v.claims[' + (claims.length - 1) + '].imagesAdded', true);
    $A.util.addClass(component.find('spinner'), 'slds-hide');
  },

  togglePartsDisplay: function(component) {
    var showParts = !component.get("v.showParts");
    component.set("v.showParts", showParts);

    // if parts are not necessary, clear parts
    if (!showParts) {
      component.set("v.parts", []);
    }
  },

  addPart: function(component, event, helper) {
    var partProductId = component.get('v.partLookupValue');
    console.log( 'PartProductId ' + partProductId);
    if (!partProductId) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
          "title": 'No Part Selected',
          "message": 'Please select a Part first',
          type: 'error'
      });
      toastEvent.fire();
      return;
    }

    // validate quantity
    var partLookupQuantityComponent = component.find("partLookupQuantity");
    var quantity = partLookupQuantityComponent.get("v.value");
    partLookupQuantityComponent.set("v.errors", null);
    if (!quantity && quantity != 0) {
      partLookupQuantityComponent.set("v.errors", [{ message: "Quantity is required" }]);
      return;
    } else if (quantity <= 0) {
      partLookupQuantityComponent.set("v.errors", [{ message: "Quantity must be at least one" }]);
      return;
    } else if (quantity % 1 != 0) {
      partLookupQuantityComponent.set("v.errors", [{ message: "Quantity must be a whole number" }]);
      return;
    }

    helper.getProduct(component, partProductId).then($A.getCallback(
      function(product) {
        if (product) {
          helper.getUnitPrice(component, product.Id).then($A.getCallback(
            function(unitPrice) {
              // add product to our list of parts
              var parts = component.get("v.parts");
              var partLookupCMP = component.find('partLookup');
              parts.push({
                sobjectType: "Case_Part__c",
                Case__c: undefined,
                Product__c: product.Id,
                Product__r: product,
                Quantity__c: quantity,
                Order_Quantity__c: quantity,
                Unit_Price__c: unitPrice
              });
              component.set("v.parts", parts);

              console.log(parts);

              // clear the part search and quantity fields
              partLookupCMP.set('v.query', null);
              partLookupQuantityComponent.set("v.value", null);
            })
          );
        }
      }
    ));
  },

  removePart: function(component, event, helper) {
    helper.deletePart(component,event);
  },

  uploaderInitialized: function(component, event) {
    console.log('newClaim.uploaderInitialized');
    component.set('v.disableNextButton', false);
    component.set('v.uploaderInitialized', true);
  },

  validateParts: function(component) {
    var part = component.get('v.partLookupValue'),
        quantity = component.get('v.partLookupQuantityValue');

    if ((part != null && part != '') || (quantity != null && part != '')) {
      component.set('v.disableNextButton', true);
    } else {
      component.set('v.disableNextButton', false);
    }
  }
})