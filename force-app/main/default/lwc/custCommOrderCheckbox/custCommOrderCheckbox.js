/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class CustCommOrderCheckbox extends NavigationMixin(LightningElement) {
	@api optionSku;
	@api optionName;
	@api optionPrice;
	@api optionKm;
	@api optionRpm;
	@api optionInit;
	@api optionPage;
	@api optionInputType;
	@api optionImages;
	@api displayImage;
	@api optionBlurb;
	@api optionIncludedProducts;
	//@track useCheckbox;

	@track displayRPM;
	@track displayKM;

	@wire(CurrentPageReference) pageRef;

	renderedCallback(){
    if(this.optionInit){
			this.handleClick();
		}
 }

 get useCheckbox(){
   return (this.optionInputType !== 'radio') ? true : false;
 }

 get optionInputName(){
   return 'option_' + this.optionPage;
 }

 get hasIncludedProducts(){
   return (this.optionIncludedProducts.length !== 0) ? true : false;
 }

	handleClick(event){
	  const selectEvent = new CustomEvent('optionview', {
	    detail: {
	      'motorSKU': this.optionSku,
	      'motorSpeed': this.optionKm,
	      'motorRPM': this.optionRpm,
				'motorImage': this.displayImage,
     	}
   	});
   	this.dispatchEvent(selectEvent);

   	console.log('click (images): ', JSON.parse(JSON.stringify(this.optionImages)));
   	fireEvent(this.pageRef, 'motorSelection', this.optionImages	);
 	}
}