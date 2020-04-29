/**
 * Created by dave on 2020-02-05.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import fetchCommissionLineItems from '@salesforce/apex/CommissionRecord2_Controller.fetchCommissionLineItems';
import upsertLineItem from '@salesforce/apex/CommissionRecord2_Controller.upsertLineItem';
import deleteLineItem from '@salesforce/apex/CommissionRecord2_Controller.deleteLineItem';

export default class CommissionLineItems extends LightningElement {

  @wire(CurrentPageReference) pageRef;

  @api commissionRecordId;
  @api recordCalculationMethod;
  wiredLineItems;
  @track showAddLineForm=false;
  @track activeLineItem;
  @track isFormValid=false;
  @track lineItems;
  @track totalSale=0;
  @track totalCost=0;
  @track totalLabour=0;
  @track totalProfit=0;
  @track totalPayment=0;
  _totals;
  @wire( fetchCommissionLineItems, { comRecId: '$commissionRecordId'} )
  wiredGetLineItems( result )
  {
    this.wiredLineItems = result;
    if( result.data )
    {
      console.log( JSON.parse(JSON.stringify(result.data )));
      this.lineItems = [...result.data];
      this.reCalcTotals();
    }
    if( result.error )
    {
      this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            message: result.error.message ? result.error.message : 'Contact your Salesforce Administrator',
            variant: 'error'
        })
      );
    }

  }

  @api handleAddLine()
  {
    this.initNewLineItemObject();
    this.showAddLineForm = true;
  }

  @api commissionRecordStatusChanged()
  {
    return refreshApex( this.wiredLineItems );
  }

  get renderRatePaymentColumns()
  {
    return this.recordCalculationMethod === 'Revenue';
  }

  get lineItemFormValid()
  {
    return !this.isFormValid;
  }

  get formHeaderText()
  {
    return this.activeLineItem.id ? 'Update Line Item' : 'Add Line Item';
  }

  get saveBtnText()
  {
    return this.activeLineItem.id ? 'Update' : 'Save';
  }

  calcTotals()
  {
    const doCalc = (item) => {
      this.totalSale += item.totalSale;
      this.totalCost += item.totalCost;
      this.totalLabour += item.totalLabour;
      this.totalProfit += parseFloat(item.profit);
      this.totalPayment += parseFloat(item.payment);
    };
    this.lineItems.forEach( item => {
      doCalc( item );
      if( item.kitParts )
      {
        item.kitParts.forEach( kitPart => {
          doCalc( kitPart );
        })
      }
    });
  }

  reCalcTotals()
  {
    this.totalSale = 0;
    this.totalCost = 0;
    this.totalLabour = 0;
    this.totalProfit = 0;
    this.totalPayment = 0;
    this.calcTotals();
  }

  handleNewLineItemChange( event )
  {
    this.activeLineItem[ event.currentTarget.name ] = event.target.value;
    this.validateForm();
  }

  validateForm()
  {
    this.isFormValid = [...this.template.querySelectorAll('lightning-input')]
    .reduce( (validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
  }

  initNewLineItemObject()
  {
    this.activeLineItem = {
      comment: '',
      description: '',
      commissionRate: this.lineItems ? this.lineItems[0].commissionRate : '',
      salePrice: '',
      labourCost: '',
      unitCost: '',
      quantity: 1,
      commissionRecordId: this.commissionRecordId
    };
  }

  handleCancelLineAdd()
  {
    this.showAddLineForm = false;
  }

  handleSaveLineItem()
  {
    if( !this.isFormValid ) return;

    let spinner = this.template.querySelector("c-legend-spinner"),
        title, state, message;

    this.showAddLineForm = false;
    spinner.toggle();

    ['salePrice', 'unitCost', 'labourCost'].forEach( field => {
      if( !this.activeLineItem[field] )
        this.activeLineItem[field] = 0;
    });

    upsertLineItem( { lineItemJSON : JSON.stringify( this.activeLineItem ) } )
    .then( result => {
      this.formSuccessHandler( result );
      title = 'Success!';
      state = 'success';
      message = 'Line Item created successfully';
    })
    .catch( error => {
      this.showAddLineForm = true;
      title = error.message ? error.message : 'There was an Error';
      state = 'error';
      message = error;
    })
    .finally( () => {
      spinner.toggle();
      this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: state
        })
      );
    });
  }

  formSuccessHandler( result )
  {
    const existingIdx = this.lineItems.findIndex( item => item.id === result.id );
    if( existingIdx > -1 )
      this.lineItems[existingIdx] = result;
    else
      this.lineItems.push( result );
    this.reCalcTotals();
    fireEvent( this.pageRef, 'lineItemsChanged', null );
  }

  handleLineAction( event )
  {
    if( event.detail.action === 'edit' )
      this.editLineItem( event.detail.recordId );
    if( event.detail.action === 'delete' )
      this.deleteLineItem( event.detail.recordId );
  }

  editLineItem( recordId )
  {
    this.activeLineItem = {...this.lineItems.find( item => item.id === recordId )};
    this.showAddLineForm = true;
    this.isFormValid = true;
  }

  deleteLineItem( recordId )
  {
    let spinner = this.template.querySelector("c-legend-spinner"),
        title, state, message;
    spinner.toggle();
    deleteLineItem({
      recordId: recordId
    })
    .then( () => {
      this.lineItems = this.lineItems.filter( item => item.id != recordId );
      this.reCalcTotals();
      fireEvent( this.pageRef, 'lineItemsChanged', null );
      title = 'Success!';
      state = 'success';
      message = 'Line Item deleted successfully';
    })
    .catch( error => {
      title = error.message ? error.message : 'There was an Error';
      state = 'error';
      message = error;
    })
    .finally( () => {
      spinner.toggle();
      this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: state
        })
      );
    })
  }

}