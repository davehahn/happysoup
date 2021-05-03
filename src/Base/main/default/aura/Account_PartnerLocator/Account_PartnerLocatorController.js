({
	doInit : function(component, event, helper)
  {
    var spinner = component.find("spinner");
    spinner.toggle();
    component.set('v.provinces', [
      'Alberta',
      'British Columbia',
      'Manitoba',
      'New Brunswick',
      'Newfoundland and Labrador',
      'Nova Scotia',
      'Ontario',
      'Prince Edward Island',
      'Quebec',
      'Saskatchewan',
      'Yukon'
    ]);
    helper.loadPartners( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.allPartners', result);
        component.set('v.markersTitle', 'Legend Partners');
        helper.filterData( component );
        component.set('v.dataLoaded', true);
        spinner.toggle();
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
	},

  handleFilter: function( component, event, helper )
  {
    helper.filterData( component );
  }
})