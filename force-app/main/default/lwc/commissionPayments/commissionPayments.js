/**
 * Created by dave on 2020-02-21.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import fetchPayments from '@salesforce/apex/CommissionRecord2_Controller.fetchCommissionPayments';
import upsertPayments from '@salesforce/apex/CommissionRecord2_Controller.upsertCommissionPayments';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { gen8DigitId } from 'c/utils';


export default class CommissionPayments extends LightningElement {
  @api commissionRecordId;
  @wire(CurrentPageReference) pageRef;
  @track isEditing=false;
  @track payments;
  @track isValid=true;
  @track errorMessage;
  _payments;
  _payments_to_delete=[];
  _isBusy=true;
  _totalSplitPercent;
  @wire( fetchPayments, { comRecId: '$commissionRecordId'})
  wiredPayments( result )
  {
    if( result )
    {
      this._isBusy = false;
      this.payments = result;
      if( result.data )
        this._payments = result.data;
    }
  }

  connectedCallback()
  {
    registerListener('paymentChanged', this.handlePaymentChange, this );
    registerListener('paymentRemoved', this.handlePaymentRemoval, this );
    registerListener('lineItemsChanged', this.handleLineItemChange, this);
  }

  @api commissionRecordStatusChanged()
  {
    return refreshApex( this.payments );
  }

  disconnectedCallback()
  {
    unregisterAllListeners( this );
  }

  get stateClass()
  {
    return this._isBusy ? 'busy' : '';
  }

  get paymentBtnText()
  {
    return this.isEditing ? 'Cancel' : 'Edit Payments';
  }

  get disableSaveBtn()
  {
    return !this.isValid;
  }

  splitValid()
  {
    this._totalSplitPercent = 0;
    const records = [...this.payments.data];
    records.forEach( payment => this._totalSplitPercent += parseFloat(payment.split) );
    return this._totalSplitPercent === 100;
  }

  missingOwner()
  {
    const records = [...this.payments.data];
    return records.filter( r => typeof(r.owner) == 'undefined' || r.owner === null ).length > 0;
  }

  validate()
  {
    let isValid=true;
    let errorMessage = null;
    if( !this.splitValid() )
    {
      isValid = false;
      errorMessage = `Split percentages must equal 100 - current ${this._totalSplitPercent}`;
    }
    else if( this.missingOwner() )
    {
      isValid = false;
      errorMessage = 'Every Payment requires an Owner';
    }
    this.isValid = isValid;
    this.errorMessage = errorMessage;
    this.dispatchEvent(
      new CustomEvent( 'paymentchange', {
        detail: { isValid: isValid }
      })
    );
  }

  @api handlePaymentEdit()
  {
    this.isEditing = !this.isEditing;
    if( !this.isEditing )
    {
      this.payments.data = this._payments;
      this._payments_to_delete = [];
    }
    this.validate();
  }

  @api handleAddPayment()
  {
      let newP = {...this.payments.data[0]};
      let dup = [...this.payments.data];
      newP.id = gen8DigitId();
      newP.owner = null;
      newP.ownerId = null;
      newP.avatarURL = null;
      newP.split = 0;
      newP.amount = 0;
      dup.push( newP );
      this.payments.data = dup;
      this.validate();
  }

  handlePaymentChange( data )
  {
    const _payments = [...this.payments.data];
    let idx = this.payments.data.findIndex( payment => payment.id === data.id );
    _payments[idx] = data.payment;
    this.payments.data = [..._payments];
    this.validate();
  }

  handlePaymentRemoval( data )
  {
    let _payments = [...this.payments.data];
    let idx = this.payments.data.findIndex( payment => payment.id === data.paymentId );
    if( _payments[idx].id.length > 8 )
    {
      this._payments_to_delete.push( _payments[idx] );
    }
    _payments.splice(idx, 1);
    this.payments.data = [..._payments];
    this.validate();
  }

  handlePaymentDispute( event )
  {
    const recordId = event.detail.recordId;
    this.dispatchEvent(
      new CustomEvent( 'disputedpayments', {
        detail: { recordId: recordId }
      })
    );
  }

  handleLineItemChange()
  {
    return refreshApex( this.payments );
  }

  @api handlePaymentUpdate()
  {
    this._isBusy = true;
    let result = {
      status: 'success'
    };
    let updatePayments = [...this.payments.data];
    updatePayments = updatePayments.map( p => {
      if( p.id.length === 8 )
      {
        p.id = null;
        if( p.commissionRecordId == null )
        {
          p.commissionRecordId = this.commissionRecordId;
        }
      }
      return p;
    });

    upsertPayments({
      updatePaymentsJSON: JSON.stringify( updatePayments ),
      deletePaymentsJSON: JSON.stringify( this._payments_to_delete )
    })
    .then( result => {
      this.payments.data = result;
      this._payments = result;
      this._payments_to_delete=[];
      this.isEditing = false;
    })
    .catch( error => {
      console.log( error.message);
      result.status = 'error';
      result.message = error.message;
    })
    .finally( () => {
      this._isBusy = false;
      this.dispatchEvent(
        new CustomEvent( 'paymentupdatecomplete', {
            detail: result
        })
      );
    });

  }

}