/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class FactoryStoreFooterStayInTouch extends NavigationMixin(LightningElement) {

	newsPageRef;
  emailAddress;
  url;

  connectedCallback(){
    console.log('in newsletter callback');
  }

	clickHandler( e ){
		console.log('hello?');
		this.emailAddress = this.template.querySelector('[data-id="newsEmail"]').value;
		console.log('emailAddress', this.emailAddress);
		this.newsPageRef = {
			type: 'comm__namedPage',
			attributes: {
				name: 'Stay_in_Touch__c'
			},
			state : {
				c__preFillEmail: this.emailAddress
			}
		};
		this[NavigationMixin.Navigate](this.newsPageRef);

		e.preventDefault();
 	}
}