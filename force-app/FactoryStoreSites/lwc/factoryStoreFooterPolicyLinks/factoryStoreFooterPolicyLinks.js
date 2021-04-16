/**
 * Created by Tim on 2021-04-01.
 */

import { LightningElement, api, track } from 'lwc';
import { renderEN, renderFR, stringy } from 'c/factoryStoreUtils';


export default class FactoryStoreFooterPolicyLinks extends LightningElement {
	@api showPrivacyPolicyLink;
	@api privacyPolicyURL;
	@api showCookiePolicyLink;
	@api cookiePolicyURL;
	@api showTermsLink;
	@api termsURL;

	@track isEN = renderEN();
	@track isFR = renderFR();

	@track policyLinks = [];

	connectedCallback(){
	  if(this.showPrivacyPolicyLink){
				this.policyLinks.push({
				  'label': {
				  	'EN': 'Privacy Policy',
				  	'FR': 'Politique de Confidentialité'
      		},
					'url': this.privacyPolicyURL,
					'ariaLabel': 'Opens Legend Boats Privacy Policy in a new window'
			 });
		 }
		 if(this.showCookiePolicyLink){
				this.policyLinks.push({
					'label': {
						'EN': 'Cookie Policy',
						'FR': 'Politique relative aux cookies'
					},
					'url': this.cookiePolicyURL,
					'ariaLabel': 'Opens Legend Boats Cookie Policy in a new window'
				});
			}
			if(this.showTermsLink){
				this.policyLinks.push({
					'label': {
						'EN': 'Terms and Conditions',
						'FR': 'Conditions Générales D’utilisation'
					},
					'url': this.termsURL,
					'ariaLabel': 'Opens Legend Boats Terms and Conditions in a new window'
			 });
		 }
	}

	get allPolicyLinks(){
		return this.policyLinks.map( policy => {
			return {
				label: policy.label,
				url: policy.url,
				ariaLabel: policy.ariaLabel
			}
		});
	}
}