/**
 * Created by dave on 2022-10-26.
 */

({
  initAdditionalAccessory: function( component, result ){
    if( result.Id === null ){
      return Promise.resolve(null);
    }
    let newProduct = {
      quantity: null,
      salePrice: result.UnitPrice,
      retailPrice: result.UnitPrice,
      productId: result.Product2Id,
      pricebookEntryId: result.Id,
      productName: result.Product_Name__c,
      isTaxable: result.IsProductTaxable__c === 'true'
    }
    console.log( JSON.parse( JSON.stringify( newProduct ) ) );
    return Promise.resolve(newProduct);
//    let action = component.get('c.fetchAdditionalAccessory');
//    action.setParam('prodId', prodId);
//    return new LightningApex( this, action ).fire();
  },
  addProductToCPQ: function( component ){
    let cpq = component.get('v.cpq'),
      newProduct = component.get('v.newProduct');
    cpq.additionalAccessories.push(newProduct);
    component.set('v.cpq', cpq);
    this.closeForm(component);
  },
  closeForm: function( component ){
    component.find('product-lookup').reset();
    component.set('v.showForm', false);
    component.set('v.newProduct', null);
  }
});