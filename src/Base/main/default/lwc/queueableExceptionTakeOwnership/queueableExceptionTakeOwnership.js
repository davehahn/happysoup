/**
 * Created by dave on 2021-06-22.
 */


import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { successToast, errorToast, reduceErrors } from 'c/utils';
import USER_ID  from '@salesforce/user/Id';
import ID_FIELD from '@salesforce/schema/Queueable_Exception_Log__c.Id';
import STATUS_FIELD from '@salesforce/schema/Queueable_Exception_Log__c.Status__c';

export default class QueueableExceptionTakeOwnership extends LightningElement {

  isBusy=false;
  wiredRecord;
  _recordData;

  @wire(getRecord, { recordId: '$recordId', fields: ['Queueable_Exception_Log__c.Status__c'], childRelationships: 'Queueable_Exception_Log__c.System_Issues__r' })
  wiredLog( result )
  {
    this.wiredRecord = result;
    if( result.data )
    {
      this._recordData = result.data;
    }
    else if( result.error )
    {
      errorToast( this, reduceErrors( result.error ).join(', ') );
    }
  }

  @api recordId;
  @api invoke()
  {
    console.log('Take Ownership');
    this.isBusy = true;
    console.log( JSON.parse(JSON.stringify(this._recordData ) ) );
    console.log( JSON.parse(JSON.stringify(this._recordData.childRelationships ) ) );
    console.log( {...this._recordData.childRelationships});
    this._setOwner()
    .then( () => {
      successToast( this, 'You now own this Exception. Lets get it fixed');
    })
    .catch( (error) => {
      errorToast( this, reduceErrors( error ).join(', ') );
    })
    .finally( () => {
      this.isBusy = false;
    });
  }

  _setOwner()
  {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields['OwnerId'] = USER_ID;
    if( this._recordData.fields[STATUS_FIELD.fieldApiName].value === 'New' )
    {
      fields[STATUS_FIELD.fieldApiName] = 'Under Investigation';
    }
    const recordInput = { fields };
    return updateRecord( recordInput );
//    return new Promise( (resolve, reject) => {
//      setTimeout( () => {
//        resolve();
//      }, 1000 );
//    });
  }

}