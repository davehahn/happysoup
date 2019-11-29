({
  initialize: function( component )
  {
    var action = component.get('c.initComponent');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    return new LightningApex( this, action ).fire();
  },

  addPackage: function( component )
  {
    var action = component.get('c.addNewPackageToBundle'),
        record = {
          Package__c: component.get('v.recordId'),
          Item__c: component.get('v.newSelectedPackage').Id,
          Quantity__c: component.get('v.newPackageQuantity')
        };
    action.setParams({
      newPackageItem: record
    });
    return new LightningApex( this, action ).fire();

  },

  removePackage: function( component, packageId )
  {
    var self = this,
        confirmParams = {
          title: "Remove this package from the bundle?",
          message: "This permanent and can not be undone!"
        };
    self.confirm( component, confirmParams )
    .then(
      $A.getCallback( function() {
        self.doRemove( component, packageId );
      }),
      $A.getCallback( function() {
        return false;
      })
    )
  },

  updatePackageQuantities: function( component )
  {
    var action = component.get('c.updatePackages'),
        packages = [];

    for( let p of component.get('v.selectedPackages') )
    {
      packages.push({
        Id: p.Id,
        Quantity__c: p.Quantity__c
      });
    }
    action.setParams({
      recordId: component.get('v.recordId'),
      packages: packages
    });
    return new LightningApex( this, action ).fire();
  },

  doRemove: function( component, packageId )
  {
    var action = component.get('c.removePackageFromBundle'),
        spinner = component.find('page-spinner');

    action.setParams({
      recordId: component.get('v.recordId'),
      packageId: packageId
    });

    $A.util.toggleClass(spinner, "slds-hide");
    new LightningApex( this, action ).fire()
    .then(
      $A.getCallback( function( result ) {
        component.set('v.selectedPackages', result.selectedPackages);
        component.set('v.availablePackages', result.availablePackages);
        component.set('v.filteredPackages', result.availablePackages);
        component.set('v.searchFilter', '');
        LightningUtils.showToast('success', 'Success', 'Package was successfully removed.');
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
       $A.util.toggleClass(spinner, "slds-hide");
    }))
  },

  confirm: function( component, confirmParams )
  {
    var confirmCmp = component.find('lgnd-confirm');

    return new Promise( function( resolve, reject ) {
      component.addEventHandler('c:lgnd_Confirm_Response_Event', function( auraEvent ) {
        auraEvent.getParam('theResponse')  ? resolve() : reject();
      });
      confirmCmp.showConfirm( confirmParams );
    });
  },

})