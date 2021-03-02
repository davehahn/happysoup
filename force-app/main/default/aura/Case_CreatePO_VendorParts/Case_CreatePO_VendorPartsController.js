({
  doInit: function( component, event, helper )
  {
    var vendor = component.get('v.vendor');
    console.log( JSON.parse( JSON.stringify( vendor ) ) );
    component.set('v.tableCols', [
      {label: 'Product', fieldName: 'name', type: 'text'},
      {label: 'Quantity', fieldName: 'quantity', type: 'text'}
    ]);

  },


	handlePO: function( component, event, helper )
  {
    var vendor = component.get('v.vendor'),
        selectedCaseParts = [],
        checkBoxes = component.find('rowSelect'),
        action = event.getSource().get('v.value'),
        evt = component.getEvent("vendorPartsSelected");

    if( checkBoxes.length )
    {
      for( let cb of checkBoxes )
      {
        if( cb.get('v.checked') )
          selectedCaseParts.push( cb.get('v.value') );
      }
    }
    else
    {
      if( checkBoxes.get('v.checked') )
        selectedCaseParts.push( checkBoxes.get('v.value') );
    }
    if( selectedCaseParts.length === 0 )
      LightningUtils.showToast('error',
                               'No Parts Selected for ' + vendor.name,
                               'Please select at least one part to create the PO');
    else
    {
      console.log( selectedCaseParts );
      console.log( action );
      evt.setParams({
        vendorId: vendor.id,
        casePartIds: selectedCaseParts,
        action: action
      })
      .fire();
    }

  }
})