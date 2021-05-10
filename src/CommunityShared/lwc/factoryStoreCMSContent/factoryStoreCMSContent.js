/**
 * Created by Tim on 2021-04-26.
 */

import { LightningElement, wire, api } from 'lwc';

import initMethod from '@salesforce/apex/FactoryStore_MCWrapperController.initMethod';

export default class FactoryStoreCmsContent extends LightningElement {
	@api contentType = 'Legend_Deals';
  @wire(initMethod, {type: '$contentType'}) results;

  get jsonData(){
    console.log('JSONData: ', this.results);
    return this.results;
  }

}