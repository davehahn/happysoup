/**
 * Created by dave on 2023-01-27.
 */

import { LightningElement, api, track } from 'lwc';
import fetchSubOptions from '@salesforce/apex/CPQ_WarrantyService_Controller.fetchSubOptions';

export default class CpqSWoptionLine extends LightningElement {
  @api optionLine;
  @api activePricebookId;
  @api className='';
  @api type;

  quantityOptions;
  ready=false;
  @track item;
  //currentValue;

  get currentValue(){
    return this.item.quantitySelected.toString();
  }

  get isPrepaybleDisabled(){
    return !this.item.isSelected;
  }

  connectedCallback(){
    this.item = {...this.optionLine};
    console.log( JSON.parse( JSON.stringify( this.item ) ) );
    if( !this.item.isCheckbox ){
      this.quantityOptions = [];
      const standard = this.item.standard;
      const max = this.item.maximum;
      for (var i = standard; i <= max; i++) {
       this.quantityOptions.push({
         value: i.toString(),
         label: i.toString()
       });
      }
    }
    this.ready = true;
  }

  handleToggle(event){
    this.item.isSelected = event.currentTarget.checked;
    this.item.quantitySelected = this.item.isSelected ? 1 : 0;
    this._postChangeEvent();
    //this._fetchSubOptions();
  }

  handleSelect(event){
    const value = event.currentTarget.value;
    this.item.quantitySelected = parseInt(value);
    this.item.isSelected = this.item.quantitySelected > 0;
    this._postChangeEvent();
    //this._fetchSubOptions();
  }

  handlePrepaid(event){
    this.item.isPrepaid = event.currentTarget.checked;
    this._postChangeEvent();
  }

  _fetchSubOptions(){
    fetchSubOptions({parentProductId: this.optionLine.productId, pricebookId: this.activePricebookId})
    .then( result => {
      console.log('SUB OPTIONS');
      console.log( JSON.parse( JSON.stringify( result ) ) );
    })
    .catch( error => {
      console.log( JSON.parse( JSON.stringify( error ) ) );
    })
  }

  _postChangeEvent(){
    const evt = new CustomEvent('cpq_warrantyserviceitemchange', {bubbles: true, composed: true, detail: {item: this.item}});
    this.dispatchEvent(evt);
  }

}