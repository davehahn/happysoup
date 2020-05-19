/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api } from 'lwc';

export default class CustCommOrderCheckbox extends LightningElement {
	@api optionSku;
	@api optionName;
	@api optionPrice;
	@api optionKm;
	@api optionRpm;

	handleClick(event){
	  console.log('clicked: ', event.currentTarget);
 }
}