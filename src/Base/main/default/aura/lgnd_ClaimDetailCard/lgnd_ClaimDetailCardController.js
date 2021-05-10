({
  doInit: function( component, event, helper ) {
    console.log('ClaimDetailCard.doInit');
    console.log( component.get('v.claim') );
  },

	toggleEdit: function(component, event, helper) {
    console.log('ClaimDetailCard.toggleEdit');
    var self = this,
        toggleId = event.currentTarget.getAttribute("data-problemId"),
        problem = document.getElementById('problem-'+toggleId),
        toggleItems = problem.getElementsByClassName('toggleItem');

    //component.set('v.claim', component.get('v.claims['+toggleId+']'));

    for (var i = 0; i < toggleItems.length; i++) {
      $A.util.toggleClass(toggleItems[i], 'conceal');
    }
  },

  toggleSubletDisplay: function(component) {
    console.log('ClaimDetailCard.toggleSubletDisplay');
    var showSublet = !component.get("v.showSublet");
    component.set("v.showSublet", showSublet);

    // if sublet is not necessary, clear sublet fields
    if (!showSublet) {
      // component.set("v.warrantyClaim.Sublet_Company__c", null);
      // component.set("v.warrantyClaim.Sublet_Price__c", null);
    }
  },

  addSublet: function(component, event, helper) {
    console.log('ClaimDetailCard.addSubletAttachment');
    var claim = component.get('v.claim');
    helper.addSublet(component, event)
    .then(
      $A.getCallback(function(resp) {
        console.log('update?');
        return helper.updateAttachments(component, claim);
      }),
      $A.getCallback(function(err) {
        console.log('error?');
        reject(err);
      })
    )
    .then(
      $A.getCallback(function(resp) {
        console.log(claim);
      }),
      $A.getCallback(function(err) {
        reject(err);
      })
    );
  },

  saveEdits: function(component, event, helper) {
    console.log('claimDetailCard.saveEdits');
    var self = this,
        toggleId = event.currentTarget.getAttribute("data-problemId"),
        problem = document.getElementById('problem-'+toggleId),
        toggleItems = problem.getElementsByClassName('toggleItem'),
        claim = component.get('v.claim');

    $A.util.removeClass(component.find('spinner'), 'slds-hide');

    helper.updateClaim(component, claim)
    .then(
      $A.getCallback(function() {
        claim = component.get('v.claim');
        component.set('v.claims['+toggleId+']', claim);
        for (var i = 0; i < toggleItems.length; i++) {
          $A.util.toggleClass(toggleItems[i], 'conceal');
        }
        $A.util.addClass(component.find('spinner'), 'slds-hide');
      }),
      $A.getCallback(function(err) {
        reject(err);
      })
    );
  },

  showDetailsTab: function(component) {
    var images = component.find('images'),
        imagesTab = component.find('tab-images'),
        details = component.find('details'),
        detailsTab = component.find('tab-details');

    $A.util.addClass(images, 'slds-hide');
    $A.util.removeClass(details, 'slds-hide');

    $A.util.addClass(detailsTab, 'slds-is-active');
    $A.util.removeClass(imagesTab, 'slds-is-active');
  },

  showImagesTab: function(component) {
    var images = component.find('images'),
        imagesTab = component.find('tab-images'),
        details = component.find('details'),
        detailsTab = component.find('tab-details');

    component.find("gallery").manualInit();

    $A.util.addClass(details, 'slds-hide');
    $A.util.removeClass(images, 'slds-hide');

    $A.util.addClass(imagesTab, 'slds-is-active');
    $A.util.removeClass(detailsTab, 'slds-is-active');
  }
})