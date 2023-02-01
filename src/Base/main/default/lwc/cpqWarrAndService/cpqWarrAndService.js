/**
 * Created by dave on 2023-01-27.
 */

import { LightningElement, api, wire } from 'lwc';
import initWarrantService from '@salesforce/apex/CPQ_WarrantyService_Controller.initServiceAndWarranty'

export default class CpqWarrAndService extends LightningElement {
  @api cpq;
  @api boatId;
  @api motorId;
  @api trailerId;
  warrantyProducts;
  serviceProducts;

  @wire(initWarrantService, {recordId: '$cpq.saveToRecordId', pbId: '$cpq.activePricebookId'})
  wiredInit({error, data}){
    if( data ){
      const initData = JSON.parse(data);
      this.warrantyProducts = initData.warranty;
      this.serviceProducts = initData.service;
    }
    if(error){
      console.log( JSON.parse( JSON.stringify( error ) ) );
    }
  }

  connectedCallback(){
    if(this.cpq){
      console.log('warrService CPQ');
      console.log( JSON.parse( JSON.stringify( this.cpq ) ) );
    }
  }
//
//  _init(){
//    initWarrantService({recordId})
//  }
}