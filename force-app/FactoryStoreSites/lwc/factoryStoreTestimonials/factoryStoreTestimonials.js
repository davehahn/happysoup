/**
 * Created by Tim on 2021-04-05.
 */

import { LightningElement, api, track } from 'lwc';
import { getTestimonials, stringy } from 'c/factoryStoreUtils';

export default class FactoryStoreTestimonials extends LightningElement {

	@api numberToShow;
	@track testimonials;
	connectedCallback(){
		 this.testimonials = getTestimonials(this.numberToShow);
 	}


	get parseTestimonials(){
		console.log('test', stringy(this.testimonials));
		return this.testimonials;
 	}

}