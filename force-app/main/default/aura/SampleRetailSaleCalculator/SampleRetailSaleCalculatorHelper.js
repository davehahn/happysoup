({
  handleScroll: function( component, scrollTrue )
  {
    var header = component.find('cpq-header').getElement(),
        content = component.find('cpq-content').getElement(),
        h;
    if( scrollTrue )
    {
      h = header.getBoundingClientRect().height
      content.style.paddingTop = h + "px";
      header.classList.add("sticky");
    }
    else
    {
      header.classList.remove("sticky");
      content.style.paddingTop = "0px";
    }
  },

  resetCustomProduct: function( component )
  {
    var id = Math.random().toString(36).substr(2, 9),
        cp = {
          id: id,
          productName: null,
          quantity: null,
          retailPrice: null,
          cost: null
        };
    component.set('v.customProduct', cp );
  },

  fetchInitData: function( component )
  {
    var action = component.get('c.fetchInitialData');
    return new LightningApex( this, action ).fire();
  },

  // fetchBoatOptions : function( component )
 //  {
 //    var action = component.get('c.fetchBoatOptions');
 //    action.setParams({
 //      family: component.get('v.boatFamily')
 //    });
 //    this.updateCPQ( component, action );
  // },

 //  fetchBoatDetails: function( component )
 //  {
 //    var action = component.get('c.fetchBoatDetails');
 //    action.setParams({
 //      cpqJSON: JSON.stringify( component.get( 'v.cpq' ) )
 //    });
 //    this.updateCPQ( component, action );
 //  },

 unSelectMajorProduct: function( component )
  {
    var cpq = component.get('v.cpq');
    cpq.boatId = null;
    cpq.motorId = null;
    cpq.trailerId = null;
    cpq.trollingMotorId = null;
    cpq.theBoat = null;
    cpq.theMotor = null;
    cpq.theTrailer = null;
    cpq.theTrollingMotor = null;
    cpq.selectedOptions = [];
    cpq.savings = [];
    cpq.customProducts = [];
    cpq.tradeIn = { value: 0, lien: 0, items: [] };
    component.set( 'v.cpq', cpq );
  },

  fetchMajorProductDetails: function( component, family, recordType, productId )
  {
    var self = this,
        action = component.get('c.fetchMajorProductDetails'),
        cpq = component.get('v.cpq');

    cpq.baseProductRecordType_Name = recordType;
    cpq.baseProductFamily = family;

    if( typeof(productId) !== 'string' )
    {
      if( typeof( cpq.boatId ) === 'string' )
        self.unSelectMajorProduct( component );
    }
    else
    {
      cpq.boatId = productId;
      action.setParams({
        cpqJSON: JSON.stringify( cpq )
      });
      this.updateCPQ( component, action );
    }
  },

  setHasFees: function( component )
  {
    var cpq = component.get('v.cpq');
    if( cpq.theBoat != null &&
        Object.keys( cpq ).indexOf('theBoat') >= 0 &&
        Object.keys( cpq.theBoat ).indexOf('fees') >= 0 &&
        cpq.theBoat.fees.length > 0 )
      return true;
    if( cpq.theMotor  != null &&
        Object.keys( cpq ).indexOf('theMotor') >= 0 &&
        Object.keys( cpq.theMotor ).indexOf('fees') >= 0 &&
        cpq.theMotor.fees.length > 0 )
      return true;
    if( cpq.theTrailer != null &&
        Object.keys( cpq ).indexOf('theTrailer') >= 0 &&
        Object.keys( cpq.theTrailer ).indexOf('fees') >= 0 &&
        cpq.theTrailer.fees.length > 0 )
      return true;
    return false;
  },

  updateCPQ: function( component, action )
  {
    var spinner = component.find('spinner');

    spinner.toggle();
    new LightningApex( this, action ).fire()
    .then(
      $A.getCallback( function( result ) {
        component.set('v.cpq', result );
      }),
      $A.getCallback( function( err ) {
        LightningUtils.errorToast( err );
      })
    )
    .finally( $A.getCallback( function() {
      spinner.toggle();
    }));
  },

  updateSelectedOptions: {
    add: {
      checkboxOption: function( selectedOpts, option )
      {
        selectedOpts.push(option);
      },
      checkboxSubOption: function( selectedOpts, option )
      {
        for( let sOpt of selectedOpts )
        {
          if( option.parentProductId === sOpt.id )
            sOpt.selectedSubOptions.push( option );
        }
      },
      multipleOption: function( selectedOpts, option )
      {
        var idx;
        for( var i=0; i<selectedOpts.length; i++ )
        {
          if( option.id === selectedOpts[i].id )
            idx = i;
        }
        if( isNaN( idx ) )
          selectedOpts.push(option);
        else
          selectedOpts[idx].quantitySelected = option.quantitySelected;
      },
      multipleSubOption: function( selectedOpts, option )
      {
        var parentIdx, subIdx;
        for( var i=0; i<selectedOpts.length; i++ )
        {
          if( option.parentProductId === selectedOpts[i].id )
            parentIdx = i;
        }
        if( !isNaN( parentIdx ) )
        {
          for( var i=0; i<selectedOpts[parentIdx].selectedSubOptions.length; i++ )
          {
            if( option.id == selectedOpts[parentIdx].selectedSubOptions[i].id )
              subIdx = i;
          }
        }
        if( isNaN( subIdx ) )
          selectedOpts[parentIdx].selectedSubOptions.push( option );
        else
          selectedOpts[parentIdx].selectedSubOptions[subIdx].quantitySelected = option.quantitySelected;
      }
    },
    remove: {
      option: function( selectedOpts, option )
      {
        var idx;
        for( var i=0; i<selectedOpts.length; i++ )
        {
          if( option.id === selectedOpts[i].id )
            idx = i;
        }
        if( idx != null )
          selectedOpts.splice( idx, 1 );
      },
      subOption: function( selectedOpts, option )
      {
        var parentIdx, subIdx;
        for( var i=0; i<selectedOpts.length; i++ )
        {
          if( option.parentProductId === selectedOpts[i].id )
            parentIdx = i;
        }
        if( !isNaN( parentIdx ) )
        {
          for( var i=0; i<selectedOpts[parentIdx].selectedSubOptions.length; i++ )
          {
            if( option.id == selectedOpts[parentIdx].selectedSubOptions[i].id )
              subIdx = i;
          }
        }
        if( !isNaN( subIdx ) )
          selectedOpts[parentIdx].selectedSubOptions.splice( subIdx, 1 );
      }
    }
  },

  calcTotals: function( component )
  {
    var self = this,
        cpq = component.get('v.cpq');
console.log( JSON.parse( JSON.stringify(cpq) ) );
    if( Object.keys( cpq).indexOf('theBoat') >= 0 && cpq.theBoat != null )
      self.calcLegendDiscounts( component );
    if( Object.keys( cpq ).indexOf('theMotor') >= 0 )
    {
      self.calcPartnerMotorCost( component );
    }
    self.calcPromos( component );
    self.calcRetailTotal( component );
    self.calcPartnerTotal( component );
  },

  calcPromos: function( component )
  {
    var r_total = 0,
        p_total = 0,
        promos = component.get('v.promotions'),
        retail = parseFloat( component.get('v.retailPromotion') ),
        partner = parseFloat( component.get('v.partnerPromotion') );
    for( let promo of promos )
    {
      r_total += parseFloat( promo.retail );
      p_total += parseFloat( promo.partner );
    }
    r_total += isNaN( retail ) ? 0 : retail;
    p_total += isNaN( partner ) ? 0 : partner;
    component.set('v.retailPromotionTotal', r_total );
    component.set('v.partnerPromotionTotal', p_total );
  },

  calcLegendDiscounts: function( component )
  {
    var cpq = component.get('v.cpq'),
        coop = component.get('v.coopDiscount'),
        volume = component.get('v.volumeDiscount');

    component.set('v.calcdCoopDiscountAmount', ( cpq.theBoat.partnerPrice * coop * -1) );
    component.set('v.calcdVolumeDiscountAmount', ( cpq.theBoat.partnerPrice * volume * -1) );
  },

  calcPartnerMotorCost: function( component )
  {
    var cpq = component.get('v.cpq'),
        mercDiscount = component.get('v.mercDiscount');

    if( cpq.theMotor == null )
      component.set('v.calcdPartnerMotorCost', null );
    else
      component.set('v.calcdPartnerMotorCost',
        ( cpq.theMotor.partnerPrice - ( cpq.theMotor.partnerPrice * mercDiscount ) ) );
  },

  calcFees: function( obj, amountField )
  {
    var total = 0;
    if( obj.fees != null &&
        Object.keys( obj ).indexOf('fees') >= 0 &&
        typeof( obj.fees ) !== 'undefined' )
    {
      total = obj.fees.reduce( function( t, fee ) {
        if( !isNaN(parseFloat(fee[amountField])) )
          t += parseFloat(fee[amountField]);
        return t;
      },total );
    }
    return total;
  },

  calcRetailTotal: function( component )
  {
    var self = this,
        cpq = component.get('v.cpq'),
        opts = cpq.saleItems,
        customProducts = cpq.customProducts,
        promo = parseFloat( component.get('v.retailPromotionTotal') ),
        total = 0;

    if( Object.keys( cpq).indexOf('theBoat') >= 0 && cpq.theBoat != null )
    {
      total += cpq.theBoat.retailPrice;
      total += self.calcFees( cpq.theBoat, 'retailAmount' );
    }
    if( Object.keys( cpq ).indexOf('theMotor') >= 0 &&
        cpq.theMotor != null )
    {
      total += cpq.theMotor.retailUpgradeCost;
      total += self.calcFees( cpq.theMotor, 'retailAmount' );
    }
    if( Object.keys( cpq ).indexOf('theTrailer') >= 0 &&
        cpq.theTrailer != null )
    {
      total += cpq.theTrailer.retailUpgradeCost;
      total += self.calcFees( cpq.theTrailer, 'retailAmount' );
    }
    if( opts.length > 0 )
    {
      for( let o of opts )
      {
        total += ( o.quantity * o.salePrice );
        for( let sOpt of o.subSaleItems)
        {
          total += ( sOpt.quantity * sOpt.salePrice );
        }
      }
    }
    if( customProducts.length > 0 )
    {
      for( let cp of customProducts )
      {
        total += ( cp.quantity * cp.amount );
      }
    }
    if( isNaN(promo) )
      promo = 0;
    total += promo;
    component.set('v.retailTotal', total );
  },

  calcPartnerTotal: function( component )
  {
    var self = this,
        cpq = component.get('v.cpq'),
        opts = cpq.saleItems,
        customProducts = cpq.customProducts, //component.get('v.customProducts'),
        motorCost = component.get('v.calcdPartnerMotorCost'),
        coopD = component.get('v.calcdCoopDiscountAmount'),
        volumeD = component.get('v.calcdVolumeDiscountAmount'),
        promo = parseFloat( component.get('v.partnerPromotionTotal') ),
        total = 0;
    if( Object.keys( cpq).indexOf('theBoat') >= 0 && cpq.theBoat != null )
    {
      total += cpq.theBoat.partnerPrice;
      total += self.calcFees( cpq.theBoat, 'partnerAmount' );
    }
    if( motorCost != null )
    {
      total += motorCost;
      total += self.calcFees( cpq.theMotor, 'partnerAmount' );
    }
    if( Object.keys( cpq ).indexOf('theTrailer') >= 0 &&
        cpq.theTrailer != null )
    {
      total += cpq.theTrailer.partnerUpgradeCost;
      total += self.calcFees( cpq.theTrailer, 'partnerAmount' );
    }
    if( opts.length > 0 )
    {
      for( let o of opts )
      {
        total += ( o.quantity * o.partnerPrice );
        for( let sOpt of o.subSaleItems )
        {
          total += ( sOpt.quantity * sOpt.partnerPrice );
        }
      }
    }
    if( customProducts.length > 0 )
    {
      for( let cp of customProducts )
      {
        total += ( cp.quantity * cp.cost );
      }
    }
    if( isNaN(promo) )
      promo = 0;
    total += promo;
    if( coopD != null )
      total += coopD;
    if( volumeD != null )
      total += volumeD;
    component.set('v.partnerTotal', total );
  }

})