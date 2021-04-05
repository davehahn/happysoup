/**
 * Created by Tim on 2021-04-01.
 */

import { LightningElement, api, track } from 'lwc';

export default class FactoryStoreFooterPolicyLinks extends LightningElement {
	@api showPrivacyPolicyLink;
	@api privacyPolicyURL;
	@api showCookiePolicyLink;
	@api cookiePolicyURL;
	@api showTermsLink;
	@api termsURL;

	@track policyLinks = [];

	connectedCallback(){
	  console.log('in connected callback');
	  console.log('showPrivacyPolicyLink', this.showPrivacyPolicyLink);
	  if(this.showPrivacyPolicyLink){
				this.policyLinks.push({
					'label': 'Privacy Policy',
					'url': this.privacyPolicyURL,
					'ariaLabel': 'Opens Legend Boats Privacy Policy in a new window'
			 });
		 }
		 console.log('policy links', this.policyLinks);
		 if(this.showCookiePolicyLink){
				this.policyLinks.push({
					'label': 'Cookie Policy',
					'url': this.cookiePolicyURL,
					'ariaLabel': 'Opens Legend Boats Cookie Policy in a new window'
				});
			}
			if(this.showTermsLink){
				this.policyLinks.push({
					'label': 'Terms and Conditions',
					'url': this.termsURL,
					'ariaLabel': 'Opens Legend Boats Terms and Conditions in a new window'
			 });
		 }
			console.log('policy links', this.policyLinks);
	}

	get allPolicyLinks(){
	  console.log('render policy links');
		return this.policyLinks.map( policy => {
			return {
				label: policy.label,
				url: policy.url,
			}
		});
	}
}