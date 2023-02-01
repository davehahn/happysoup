/**
 * Created by dave on 2023-01-27.
 */

import { LightningElement, api } from 'lwc';
import fetchSubOptions from '@salesforce/apex/CPQ_WarrantyService_Controller.fetchSubOptions';

export default class CpqSWoptionLine extends LightningElement {
  @api optionLine;
  @api activePricebookId;
  @api className='';

  quantityOptions;
  ready=false;
  item;
  //currentValue;

  get currentValue(){
    return this.optionLine.quantitySelected.toString();
  }

  connectedCallback(){
    this.item = {...this.optionLine};
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
      console.log( JSON.parse( JSON.stringify( this.quantityOptions ) ) );
    }
    this.ready = true;
  }

  handleToggle(){
    console.log('toggle change');
    this._fetchSubOptions();
  }

  handleSelect(event){
    console.log('select changed');
    const value = event.currentTarget.value;
    this.item.quantitySelected = parseInt(value);
    this._fetchSubOptions();
  }

  handlePrepaid(){
    console.log('prePaid changed');
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

}