({
  addSublet: function (component, event) {
    console.log("ClaimDetailCard.helper.addSubletAttachment");
    var self = this,
      caseId = event.target.dataset.parent,
      beginEvt = $A.get("e.c:lgnd_dh_fileUploadBegin_Event"),
      claim = component.get("v.claim");

    $A.util.removeClass(component.find("spinner"), "slds-hide");

    return new Promise(function (resolve, reject) {
      self.updateClaimWithSublet(component, claim).then(function () {
        component.addEventHandler("c:lgnd_dh_fileUploadComplete_Event", function (auraEvent) {
          claim.subletSet = true;
          component.set("v.claim", claim);
          $A.util.addClass(component.find("spinner"), "slds-hide");
          resolve();
        });
        beginEvt
          .setParams({
            objectId: caseId
          })
          .fire();
      });
    });
  },

  updateClaim: function (component, claim) {
    console.log("ClaimDetailCard.helper.updateClaim");
    var self = this;
    component.set("v.error", null);
    return new Promise(function (resolve, reject) {
      self
        .callAction(component, "saveWithParts", {
          c: claim.case,
          caseParts: claim.parts
        })
        .then(
          $A.getCallback(function (caseId) {
            console.log("RESOLVED");
            resolve();
          }),
          $A.getCallback(function (err) {
            console.log("NOT RESOLVED");
            reject(err);
          })
        );
    });
  },

  updateClaimWithSublet: function (component, claim) {
    console.log("ClaimDetailCard.helper.updateClaimWithSublet");
    var self = this;
    component.set("v.error", null);
    return new Promise(function (resolve, reject) {
      self
        .callAction(component, "saveWithoutParts", {
          c: claim.case
        })
        .then(
          $A.getCallback(function (caseId) {
            console.log("RESOLVED");
            resolve();
          }),
          $A.getCallback(function (err) {
            console.log("NOT RESOLVED");
            reject(err);
          })
        );
    });
  },

  updateAttachments: function (component, claim) {
    console.log("ClaimDetailCard.helper.updateAttachments");
    console.log(claim);
    var self = this;
    return new Promise(function (resolve, reject) {
      self
        .callAction(component, "getDocs", {
          caseId: claim.case.Id
        })
        .then(
          $A.getCallback(function (docs) {
            console.log(docs);
            component.set("v.claim.docs", docs);
            resolve();
          }),
          $A.getCallback(function (err) {
            console.log(err);
          })
        );
    });
  },

  callAction: function (component, methodName, parameters) {
    console.log("ClaimDetailCard.helper.callAction:" + methodName);
    var action = component.get("c." + methodName);
    action.setParams(parameters);
    return new Promise(function (resolve, reject) {
      action.setCallback(this, function (response) {
        var responseState = response.getState();
        if (responseState == "SUCCESS") {
          resolve(response.getReturnValue());
        } else if (responseState === "ERROR") {
          reject(response.getError());
        } else {
          reject(responseState);
        }
      });
      $A.enqueueAction(action);
    });
  }
});
