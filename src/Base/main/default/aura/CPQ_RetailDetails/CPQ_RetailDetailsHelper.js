({
  groupSaleItems: function( component )
  {
    var self = this,
        cpq = component.get('v.cpq'),
        boatSaleItems = [],
        motorSaleItems = [],
        trailerSaleItems = [],
        trollingMotorSaleItems = [];

    for( let saleItem of cpq.saleItems )
    {
      if( cpq.boatId == saleItem.parentProductId )
      {
        boatSaleItems.push( saleItem );
      }
      if( cpq.motorId == saleItem.parentProductId )
      {
        motorSaleItems.push( saleItem );
      }
      if( cpq.trailerId == saleItem.parentProductId )
      {
        trailerSaleItems.push( saleItem );
      }
      if( cpq.trollingMotorId == saleItem.parentProductId )
      {
        trollingMotorSaleItems.push( saleItem );
      }
    }
    component.set('v.boatSaleItems', self.sortSaleItems( boatSaleItems ) );
    component.set('v.motorSaleItems', self.sortSaleItems( motorSaleItems ) );
    component.set('v.trailerSaleItems', self.sortSaleItems( trailerSaleItems ) );
    component.set('v.trollingMotorSaleItems', self.sortSaleItems( trollingMotorSaleItems ) );
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

  sortSaleItems: function( saleItems )
  {
    var compare = function(a,b) {
      if (a.productName < b.productName)
         return -1;
      if (a.productName > b.productName)
        return 1;
      return 0;
    }
    for( let saleItem of saleItems )
    {
      if( saleItem.subSaleItems.length > 0 )
      {
        saleItem.subSaleItems.sort(compare);
      }
    }
    return saleItems.sort( compare );
  },

  calculateTotals: function( component )
  {
    var cpq = component.get('v.cpq'),
        cpqUtils = component.find('CpqUtils'),
        totals = cpqUtils.calcCpqTotals( cpq );
        
        console.log( JSON.parse( JSON.stringify( totals ) ) );

    component.set('v.subTotal', totals.subTotal);
    component.set('v.savingsTotal', totals.savingsTotal);
    component.set('v.federalTaxTotal', totals.fedTax);
    component.set('v.provincialTaxTotal', totals.provTax);
    component.set('v.grandTotal', totals.grandTotal);
  }

})