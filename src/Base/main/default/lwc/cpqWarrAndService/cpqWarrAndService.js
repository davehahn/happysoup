/**
 * Created by dave on 2023-01-27.
 */

import { LightningElement, api, wire } from 'lwc';
import initWarrantService from '@salesforce/apex/CPQ_WarrantyService_Controller.initServiceAndWarranty'
import findWarAndServiceOptions from '@salesforce/apex/CPQ_WarrantyService_Controller.findWarAndServiceOptions'

export default class CpqWarrAndService extends LightningElement {
  @api cpq;
  @api boatId;
  @api motorId;
  @api trailerId;
  warrantyProducts;
  serviceProducts;

  @wire(findWarAndServiceOptions, {selectedProductIds: '$cpq.selectedProductIds', pricebookId: '$cpq.activePricebookId'})
    wiredInit({error, data}){
      if( data ){
        const initData = JSON.parse(data);
        const selectedWarr = new Map();
        const selectedMainAndServ = new Map();
        this.cpq.warrantyOptions.forEach( item => {
          selectedWarr.set( item.id, item );
        })
        this.cpq.maintenanceServicePlanOptions.forEach( item => {
          selectedMainAndServ.set(item.id, item);
        })
        initData.warranty.forEach( item => {
          if(selectedWarr.has(item.id)){
            item.isSelected = true;
            item.quantitySelected = selectedWarr.get(item.id).quantitySelected;
          }
        });
        initData.service.forEach( item => {
          if(selectedMainAndServ.has(item.id)){
            item.isSelected = true;
            item.quantitySelected = selectedMainAndServ.get(item.id).quantitySelected;
            item.isPrepaid = selectedMainAndServ.get(item.id).isPrepaid;
          }
        });
        this.warrantyProducts = initData.warranty;
        this.serviceProducts = initData.service;
        this.template.querySelector('c-legend-spinner').close();
      }
      if(error){
        console.log( JSON.parse( JSON.stringify( error ) ) );
      }
    }

}