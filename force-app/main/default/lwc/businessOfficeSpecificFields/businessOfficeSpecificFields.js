/**
 * Created by dave on 2021-02-04.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
import fieldNames from '@salesforce/apex/BusinessOffice_Controller.getBusinessOfficeFields';

export default class BusinessOfficeSpecificFields extends LightningElement {

  @api recordId;
  @api sObjectType;
  @track fields;

  isEditing=false;
  isReady=false;
  viewRecordLoaded=false;
  busy=false;
  _connected=false;

  @wire( fieldNames, { sObjectType: '$sObjectType' } )
  wiredFields( { error, data } )
  {
    if( data )
    {
      this.fields = [...data];
      this.init();
    }
    else if( error )
    {
      console.log( error );
    }
  }

  connectedCallback()
  {
    this._connected = true;
    this.init();
  }

  init()
  {
    if( this._connected && this.fields && this.fields.length > 0 )
    {
      this.isReady = true;
    }
  }

  handleRecordViewLoaded( event )
  {
    this.viewRecordLoaded = true;
  }

  handleRecordEditLoaded( event )
  {
    this.busy = false;
  }

  handleEdit()
  {
    this.isEditing = true;
    this.busy = true;
  }

  handleCancelEdit()
  {
    this.isEditing = false;
  }

  handleEditSubmit()
  {
    console.log( 'Submit edit form' );
    this.busy = true;
  }

  handleEditSuccess()
  {
    console.log( 'Edit Success')
    successToast( this, 'Update Success!', '' );
    this.busy = false;
    this.isEditing = false;
  }
}