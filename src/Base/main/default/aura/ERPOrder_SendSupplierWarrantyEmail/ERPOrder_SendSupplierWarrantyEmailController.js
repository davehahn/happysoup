({
  doInit: function( component, event, helper )
  {
    component.set('v.columns', [
      {label: 'Name', fieldName: 'Name', type: 'text'},
      {label: 'Email', fieldName: 'Email', type: 'email'}
    ]);
  },

  afterScript: function( component, event, helper )
  {
    helper.fetchERPInfo( component )
    .then(
      $A.getCallback( function( result ) {
        console.log(result);
        component.set('v.isSmoker', result.isSmoker );
        component.set('v.hasPermission', result.hasPermission );
        if( result.isActive && result.hasPermission )
        {
          helper.fetchContacts( component )
          .then(
            $A.getCallback( function( result ) {
              component.set('v.showSpinner', false);
              component.set('v.contacts', result);
            }),
            $A.getCallback( function( err ) {
              LightningUtils.errorToast( err );
            })
          );
        }
        else
        {
          component.set('v.erpClosed', true);
          component.set('v.showSpinner', false);
        }
      }),
      $A.getCallback( function( err ) {
        alert( err );
      })
    )

  },

  doResubmit: function( component, event, helper )
  {
    component.set('v.showSpinner', true );
    component.set('v.erpClosed', false );
    helper.fetchContacts( component )
    .then(
      $A.getCallback( function( result ) {
        component.set('v.showSpinner', false);
        component.set('v.contacts', result);
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  },

  rowSelected: function( component )
  {
    var table = component.find('contactDataTable'),
        selections = table.getSelectedRows();
    component.set('v.hasSelections', selections.length > 0 );
  },

  sendEmail: function( component, event, helper )
  {
    component.set('v.showSpinner', true);
    helper.submitToSmoker( component )
    .then(
      $A.getCallback( function( result ) {
        return helper.sendEmail( component );
      }),
      $A.getCallback( function( err ) {
        return Promise.reject( err );
        //LightningUtils.errorToast( err );
      })
    )

    .then(
      $A.getCallback( function( result ) {
        LightningUtils.showToast('success', 'Success', 'Billing created, \b Project Complete and \b Email was send successfully!' );
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
      }),
      $A.getCallback( function( err ) {
        component.set('v.showSpinner', false);
        LightningUtils.errorToast( err );
      })
    );
  }
})