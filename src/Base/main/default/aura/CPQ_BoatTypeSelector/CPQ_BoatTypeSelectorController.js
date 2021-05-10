({
  selectType : function(component, event, helper)
  {
     console.log('selectType selected')
    event.preventDefault();
    var ele = event.currentTarget,
        eleData = ele.dataset,
        evt = component.getEvent('boatTypeSelected');
    component.set('v.productRecordType', eleData.recordType );
    component.set('v.family', eleData.family);

    evt.setParams({
      family: eleData.family,
      recordType: eleData.recordType
    });
    evt.fire();
  },

  displayTooltip: function( component, event, helper )
  {
    var ele = event.currentTarget,
        rect = ele.getBoundingClientRect(),
        recordType = ele.dataset.recordType,
        family = ele.dataset.family,
        type, tip, tipEle;

    if( recordType === 'Boat' )
      type = family.replace(' ', '-').toLowerCase();
    else
      type = recordType.replace(' ', '-').toLowerCase();

    tip = component.find( type + '-tip');
    tipEle = tip.getElement();
    tipEle.style.top = ( rect.top - 50 ) + 'px';
    tipEle.style.left = rect.left + 'px';
    $A.util.addClass( tip, 'open' );
  },

  removeToolTip: function( component, event, helper )
  {
    var ele = event.currentTarget,
        recordType = ele.dataset.recordType,
        family = ele.dataset.family,
        type;

    if( recordType === 'Boat' )
      type = family.replace(' ', '-').toLowerCase();
    else
      type = recordType.replace(' ', '-').toLowerCase();

    $A.util.removeClass( component.find( type + '-tip'), 'open');
  },

  resetVars: function(component, event, helper) {
    console.log('BoatTypeSelector.resetVars');
    component.set('v.family', '');
    component.set('v.productRecordType', '');
  }
})