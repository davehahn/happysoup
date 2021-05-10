({
  setStandardProductId: function( component )
  {
    var cpq = component.get('v.cpq'),
        upgradeType = component.get('v.upgradeType');
    if( upgradeType.toLowerCase() == 'motor' )
      component.set('v.standardProductId', cpq.theBoat.standardMotorId );
    if( upgradeType.toLowerCase() == 'trailer' )
      component.set('v.standardProductId', cpq.theBoat.standardTrailerId );
    if( upgradeType.toLowerCase() == 'trolling motor' )
      component.set('v.standardProductId', cpq.theBoat.standardTrollingMotorId );
  },

	fetchOptions : function( component )
  {
    var action = component.get('c.initUpgradeSelector');
    action.setParams({
      cpqJSON: JSON.stringify( component.get('v.cpq') ),
      upgradeType: component.get('v.upgradeType').split(' ').join('')
    });
    return new LightningApex( this, action ).fire();
	},

  removeSelectedOptions: function( component )
  {
    var cpq = component.get('v.cpq'),
        oldValueId = component.get('v.originalValueId'),
        theValue = component.get('v.value'),
        selectedOptsIds = [];
    return new Promise( function(resolve, reject) {

      if( theValue === null )
      {
        resolve();
      }

      cpq.saleItems.reduce( function( list, saleItem, index ) {
        if( saleItem.parentProductId == oldValueId ) list.push(index);
        return list;
      }, []).reverse().forEach( function( index ) {
        cpq.saleItems.splice( index, 1 );
      });

      for(let opt of theValue.options )
      {
        if( opt.isSelected ) selectedOptsIds.push(opt.id);
      }
      if( selectedOptsIds.length > 0 )
      {
        // cpq.saleItems.reduce( function( list, saleItem, index ) {
        //   if( saleItem.parentProductId == valueId ) list.push(index);
        //   return list;
        // }, []).reverse().forEach( function( index ) {
        //   cpq.saleItems.splice( index, 1 );
        // });
        cpq.selectedOptions.reduce( function( list, opt, index ) {
          if( selectedOptsIds.indexOf( opt.id) >= 0 ) list.push(index);
          return list;
        }, []).reverse().forEach( function( index ) {
          cpq.selectedOptions.splice( index, 1 );
        });
      }
      component.set('v.cpq', cpq );
      resolve();
    });
  },

  setSelected: function( component )
  {
    var action = component.get('c.setSelectedUpgrade'),
        cpq = component.get('v.cpq'),
        cpqUtils = component.find('CpqUtils'),
        params = {
          fromId: component.get('v.standardProductId'),
          toId: component.get('v.valueId'),
          activePricebookId: cpq.activePricebookId,
          province: cpq.saleProvince
        };
    action.setParams(params);
    new LightningApex( this, action ).fire()
    .then(
      $A.getCallback( function( result ) {
        component.set('v.value', result );
        if( result != null )
        {
          component.set('v.originalValueId', result.id);
          component.set('v.optionsCount', result.options.length );
          var productIds = [];
          // build an array of product Ids from the current saleItems
          for( let saleItem of cpq.saleItems )
          {
            productIds.push( saleItem.productId );
          }
          for( let opt of result.options )
          {
            if( opt.isSelected )
            {
              cpq.selectedOptions.push( opt );
              // check if selected option ( standard ) already exists in saleItem
              // and add if not.  It will be present if we are rebuilding the CPQ
              // from an opportunity or ERP
              if( productIds.indexOf( opt.id ) < 0 )
              {
                cpq.saleItems.push( cpqUtils.saleItemFromSelectedOption(opt, true) );
              }
            }
          }
          component.set('v.cpq', cpq);
        }
        else
        {
          component.set('v.originalValueId', result);
          component.set('v.optionsCount', result );
        }
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    );
  }
})