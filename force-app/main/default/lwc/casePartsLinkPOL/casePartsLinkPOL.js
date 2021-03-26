/**
 * Created by dave on 2021-02-26.
 */

import { LightningElement, api, wire } from 'lwc';
import fetchCaseParts from '@salesforce/apex/Case_CreatePurchaseOrderController_dh.fetchCaseParts';
import findOpenPOs from '@salesforce/apex/Case_CreatePurchaseOrderController_dh.findOpenPOs';
import doLink from '@salesforce/apex/Case_CreatePurchaseOrderController_dh.linkPurchaseOrderLineToCasePart';
import { errorToast, reduceErrors } from 'c/utils';
export default class CasePartsLinkPol extends LightningElement {

  @api vendorId
  @api casePartIds;
  @api warehouseId;
  caseParts;
  purchaseOrderLines;
  casePartsWithPolOptions;
  vendorName;
  ready=false;
  _spinner;
  _rendered=false;
  _dataLoaded=false;

  renderedCallback()
  {
    if( !this._rendered )
    {
      this._spinner = this.template.querySelector('c-legend-spinner');
      this._spinner.open();
      this._rendered = true;
    }
    this.init();
  }

  async connectedCallback()
  {
    if( this.casePartIds )
    {
      try
      {

        this.caseParts = await this.getCaseParts();
        const productIds = this.caseParts.map( cp => cp.Product__c );
        this.purchaseOrderLines = await this.getPOLs( productIds );
        this.casePartsWithPolOptions = this.groupPOLsToCaseParts();
        this._dataLoaded = true;
        this.init();
      }
      catch( error )
      {
        errorToast( this, reduceErrors(error)[0] );
      }
    }
  }

  init()
  {
    if( this._rendered && this._dataLoaded )
    {
      this.ready = true;
      this._spinner.close();
    }
  }

  getCaseParts()
  {
    return fetchCaseParts( { casePartIds: this.casePartIds} );
  }

  getPOLs( productIds )
  {
    return findOpenPOs({
      vendorId: this.vendorId,
      warehouseId: this.warehouseId,
      productIds: productIds
    });
  }

  groupPOLsToCaseParts()
  {
    let result = [];
    this.caseParts.forEach( casePart => {
      let item = {
        casePartId: casePart.Id,
        quantity: casePart.Quantity__c,
        productName: casePart.Product__r.Name,
        availablePOLs: this.purchaseOrderLines.filter( pol => casePart.Product__c === pol.productId  && pol.qtyRemaining >= casePart.Quantity__c )
      }
      item.hasPOLs = item.availablePOLs.length > 0;
      result.push( item );
    })
    return result;
  }

  handlePolSelect( event )
  {
    const dataSet = event.currentTarget.dataset;
    this._ready = false;
    console.log( JSON.parse( JSON.stringify( dataSet ) ) );
    this._spinner.open();
    doLink( dataSet )
    .then( (result) => {
      this.dispatchEvent(
        new CustomEvent(
          'linksuccess',
          { detail: result }
        )
      );
    })
    .catch( err => {
      this._ready = true;
      errorToast( this, reduceErrors( err )[0] );
    })
    .finally( () => {
      this._spinner.close();
    })

  }

  showPoDetails( event )
  {
    event.currentTarget.previousSibling.classList.remove('slds-hide');
  }

  hidePoDetails( event )
  {
    event.currentTarget.previousSibling.classList.add('slds-hide');
  }

  handleCreateNew()
  {
    let params = {
      vendorId: this.vendorId,
      casePartIds: this.casePartIds,
      action: 'create'
    };
    console.log( params );
    this.dispatchEvent(
      new CustomEvent(
        'createnew',
        { detail: params }
      )
    );
  }

}