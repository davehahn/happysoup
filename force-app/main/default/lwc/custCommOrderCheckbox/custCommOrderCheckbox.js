/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

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
	@api optionParentSku;
	@api optionIsAddon;
	@api displayImage;
	@api optionBlurb;
	@api optionIncludedProducts;
	@api optionTriggerUiChange;
	//@track useCheckbox;

	@track displayRPM;
	@track displayKM;

	@wire(CurrentPageReference) pageRef;

	renderedCallback(){
	  registerListener('summaryConnected', this.summaryReady, this);
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

 summaryReady(detail){
   if(detail === 'ready'){
     console.log('summary is connected');
     if(this.optionInit){
			this.handleClick(null, true);
		 }
   }
 }

	handleClick(event, init){
	  let isChecked = false;
	  if(event){
	  	isChecked = event.currentTarget.checked;
   	} else if(init){
   	  isChecked = true;
    }

	  let details = {
	    'optionSKU': this.optionSku,
			'motorSpeed': this.optionKm,
			'motorRPM': this.optionRpm,
			'optionImage': this.optionImages,
			'optionParentPage': this.optionPage,
			'optionName': this.optionName,
			'optionType': this.optionInputType
   	};

   	let summaryDetails = {
			'sku': this.optionSku,
			'name': this.optionName,
			'addToSummary': isChecked,
			'section': this.optionPage,
			'type': this.optionInputType,
			'addon': this.optionIsAddon
		};

		if(init){
		 console.log('init selection');
		 console.log('details: ', details);
		 console.log('summary details: ', summaryDetails);
  	}

   	fireEvent(this.pageRef, 'motorSelection', details	);
   	fireEvent(this.pageRef, 'updateSummary', summaryDetails);
 	}
}