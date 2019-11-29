({
  titles: {
    stepOne: 'Select Vendor and Parts',
    stepTwo: 'Create Purchase Order'
  },

  checkForPartsRequiringOrdering: function( component )
  {
    var action = component.get('c.checkForParts'), la;
    action.setParams({
      recordId: component.get('v.recordId')
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  initNewPO: function( component )
  {
    var action = component.get('c.fetchInitialPoData'), la;
    action.setParams({
      recordId: component.get('v.recordId')
    });
    la = new LightningApex( this, action );
    return la.fire();
  },

  shouldSetDefaultVendor: function( component )
  {
    var vendorWasEmpty = component.get('v.vendorEmpty');
    console.log( 'the vendor is empty? ' + vendorWasEmpty );

    return new Promise( function( resolve, reject ) {
      if( !vendorWasEmpty || vendorWasEmpty === 'false')
      {
        resolve( false );
      }
      else
      {
        var confirmCmp = component.find('lgnd-confirm'),
            spinner = component.find('spinner');
        spinner.toggle();
        component.set('v.modalOpen', false );

        component.addEventHandler('c:lgnd_Confirm_Response_Event', function( auraEvent ) {
          spinner.toggle();
          component.set('v.modalOpen', true );
          resolve( auraEvent.getParam('theResponse') );
        });
        confirmCmp.showConfirm({
          title: "Set selected vendor as Default ?",
          message: "This sets will set the default vendor on the selected products."
        });
      }
    });
  },

	createPOlinesAndUpdateCase : function( component, poId, setDefaultVendor )
  {
    var action = component.get('c.createPOlinesAndUdateCase'), la;
    action.setParams({
      casePartIds: component.get('v.vendorPartsSelection').casePartIds,
      poId: poId,
      setDefaultVendor: setDefaultVendor
    });
    la = new LightningApex( this, action );
    return la.fire();
	},

  poSuccessHandler: function( component )
  {
    var self = this;

    this.initNewPO( component )
    .then(
      $A.getCallback( function( result ) {
        if( Object.keys( result ).indexOf('vendors') >= 0 )
        {
          LightningUtils.showToast('success', 'SUCCESS!', 'Purchase Order Was Created');
          component.set('v.vendorParts', JSON.parse(result.vendors) );
          component.set('v.currentStep', 1 );
        }
        else
        {
          LightningUtils.showToast('success', 'SUCCESS!', 'Purchase Order Was Created! \r\n All Parts for this request have been ordered.');
          $A.get('e.force:refreshView').fire();
        }
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )

  }

})