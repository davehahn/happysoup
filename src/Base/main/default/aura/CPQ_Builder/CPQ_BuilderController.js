({
  handleCpqChange: function(component){
    const cpq = component.get('v.cpq');
    const loaded = component.get('v.uiFullyLoaded');
    const allowInsurance = component.get('v.allowInsurance');
    if( loaded ){
      return;
    }
    if( !allowInsurance ){
      return;
    }
    if( typeof(cpq.theBoat) !== undefined && cpq.theBoat !== null ){
      component.set('v.uiFullyLoaded', true);
      if(cpq.insuranceProducts.length > 0 ){
        component.find('builder-tabs').set('v.selectedTabId', 'insurance');
      }
    }
  },

  handleBoatTypeSelected: function (component, event, helper) {
    component.set("v.cpq", helper.unSelectMajorProduct(component));
  },

  handleMajorProductSelected: function (component, event, helper) {
    var params = event.getParams();
    helper.fetchMajorProductDetails(component, params.family, params.recordTypeName, params.productId);
  },

  handleOptionChange: function (component, event, helper) {
    var opt = event.getParams().optionItem;
    helper.updateSaleItems(component, opt);
  },
  
  handlePaymentChange: function(component, event, helper){
    const insuranceSelector = component.find('insurance-selector');
    if(insuranceSelector){
      insuranceSelector.paymentDetailsChanged( event.getParams() );
    }
  },

  handlePreInsuranceTotalChange: function(component, event, helper){
    const preInsuranceAmount = event.getParam('arguments')[0];
    component.set('v.preInsuranceTotal', preInsuranceAmount);
    const insuranceSelector = component.find('insurance-selector');
    if(insuranceSelector){
      insuranceSelector.preInsuranceAmountChanged(preInsuranceAmount);
    }
  },
  
  handleInsuranceChange: function(component, event, helper){
    const insuranceProducts = event.getParam('insuranceItems');
    let cpq = component.get('v.cpq');
    cpq.insuranceProducts = insuranceProducts;
    component.set('v.cpq', cpq);
  },

  handleInsuranceTermApplied: function(component, event){
    component.set('v.hasInsuranceTermErrors', event.getParam('hasErrors') );
  },
  
  handleWarrantyAndServiceItemChange: function(component, event, helper){
    const item = event.getParam('item');
    helper.handleWarrantyServiceItem(component, item);
  }

});
