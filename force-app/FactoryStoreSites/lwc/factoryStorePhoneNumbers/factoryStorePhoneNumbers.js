/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from 'lwc';

export default class FactoryStorePhoneNumbers extends LightningElement {
	@api phoneSales;
	@api phoneService;
	@api phoneParts;

	get hasPhoneSales(){
		return (this.phoneSales !== '') ? true : false;
 	}
 	get phoneSalesLink(){
 	  return 'tel:' + this.phoneSales;
  }

 	get hasPhoneService(){
		return (this.phoneService !== '') ? true : false;
	}
	get phoneServiceLink(){
		return 'tel:' + this.phoneService;
	}

	get hasPhoneParts(){
		return (this.phoneParts !== '') ? true : false;
	}
	get phonePartsLink(){
		return 'tel:' + this.phoneParts;
	}
}