/**
 * Created by Tim on 2021-03-24.
 */

import { LightningElement, api, wire, track } from 'lwc';

export default class FactoryStoreHomepageFeature extends LightningElement {
	@api featureHeading;
	@api featureBlurb;
	@api featureThumb;
	@api buttonText;
	@api buttonLink;

	get thumbnail(){
		return 'background-image: url(' + this.featureThumb + ')';
 	}
}