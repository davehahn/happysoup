({
  doInit: function( component, event, helper )
  {
    var spinner = component.find('spinner');
    component.set('v.title', 'Bundle Contents');
    $A.util.toggleClass(spinner, "slds-hide");
    helper.initialize( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.selectedPackages', result.selectedPackages);
        component.set('v.availablePackages', result.availablePackages);
        component.set('v.filteredPackages', result.availablePackages);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      $A.util.toggleClass(spinner, "slds-hide");
    }));
  },

  handleAddPackage: function( component, event, helper )
  {
    var p = event.getSource().get('v.value');
    component.set('v.newSelectedPackage', p );
    component.set('v.displayQuantityModal', true );
  },

  handleNewPackageCancel: function( component )
  {
    component.set('v.newSelectedPackage', null );
    component.set('v.newPackageQuantity', null );
    component.set('v.displayQuantityModal', false );
  },

  handleNewPackageContinue: function( component, event, helper )
  {
    component.set('v.displayQuantityModal', false );
    var spinner = component.find('page-spinner');
    $A.util.toggleClass(spinner, "slds-hide");
    helper.addPackage( component )
    .then(
      $A.getCallback( function( result ) {
        var selected = component.get('v.selectedPackages'),
            available = component.get('v.availablePackages'),
            filtered = component.get('v.filteredPackages'),
            idx;

        selected.push( result );
        for( var i=0; i<available.length; i++ )
        {
          if( result.Item__c == available[i].Id )
          {
            idx = i;
            break;
          }
        }
        available.splice( idx, 1 );
        idx = null;
        for( var i=0; i<filtered.length; i++ )
        {
          if( result.Item__c == filtered[i].Id )
          {
            idx = i;
            break;
          }
        }
        filtered.splice( idx, 1 );
        component.set('v.selectedPackages', selected);
        component.set('v.availablePackages', available);
        component.set('v.filteredPackages', filtered);
        component.set('v.newSelectedPackage', null );
        component.set('v.newPackageQuantity', null );
        LightningUtils.showToast('success', 'Success', 'Package was added');
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      $A.util.toggleClass(spinner, "slds-hide");
    }))
  },

  handleRemovePackage: function( component, event, helper )
  {
    var pId = event.getSource().get('v.value')
    helper.removePackage( component, pId );
  },

  handleQuantityChange : function(component, event, helper) {
    component.set('v.modified', true);
    $A.util.addClass( event.getSource(), 'has-change');
  },

  search : function(component, event, helper)
  {
    var filter = component.get('v.searchFilter').toLowerCase(),
        packages = component.get('v.availablePackages'),
        result = [];

    if( filter.length < 2 )
    {
      result = packages;
    }
    else
    {
      for( var i=0; i<packages.length; i++ )
      {
        if ( packages[i].Name.toLowerCase().includes(filter) )
          result.push( packages[i] );
        else if (  packages[i].ProductCode && packages[i].ProductCode.toLowerCase().includes(filter) )
          result.push( packages[i] );
      }
    }
    component.set('v.filteredPackages', result);
  },

  toggleAddNewPackage: function( component )
  {
    component.set('v.searchFilter', '');
    component.set('v.showAvailablePackages', !component.get('v.showAvailablePackages') );
  },

  handleUpdateQuantities: function( component, event, helper )
  {
    var spinner = component.find('page-spinner');
    $A.util.toggleClass(spinner, "slds-hide");
    helper.updatePackageQuantities( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.selectedPackages', result);
        component.set('v.modified', false);
        LightningUtils.showToast('success', 'Success', 'Package quantities where updated.');
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      $A.util.toggleClass(spinner, "slds-hide");
    }))
  }
})