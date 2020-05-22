/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, track } from 'lwc';

export default class CustCommOrderCheckbox extends LightningElement {
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

	renderedCallback(){
   if(this.optionImages){
//     console.log('images: ', JSON.parse(JSON.stringify(this.optionImages)));
			for(let image of this.optionImages){
				if(this.optionPage === 'performance'){
					if(image.imageType === 'backAngle'){
						this.displayImage = 'https://' + image.imageURL;
					}
				}
			}
   }

    if(this.optionInit){
   	    this.handleClick();
      }
 }

 get useCheckbox(){
   return (this.optionInputType !== 'radio') ? true : false;;
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
 	}
}