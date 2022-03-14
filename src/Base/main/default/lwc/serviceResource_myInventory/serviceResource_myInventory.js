/**
 * Created by dave on 2020-12-09.
 */

import { LightningElement, api, wire } from 'lwc';
import { errorToast, reduceErrors } from 'c/utils';
import fetchInventory from '@salesforce/apex/ServiceResource_MyInventory_Controller.getMyInventory';

export default class ServiceResourceMyInventory extends LightningElement {

  @api recordId;
  spinner;
  inventoryLines;

  @wire( fetchInventory, { serviceResourceId: '$recordId'} )
  wiredInventory( { error, data } )
  {
    if( data )
    {
      this.inventoryLines = data;
    }
    if( error )
    {
      errorToast( this, reduceErrors( error )[0] );
    }
  }
}