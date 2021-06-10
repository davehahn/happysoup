/**
 * Created by Tim on 2021-03-24.
 */

import { LightningElement, api, wire } from 'lwc';
import Id from '@salesforce/community/Id';
import fetchCommunityUrl from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityUrl';
import { setWrapperClass } from 'c/communitySharedUtils';

export default class CommunitySharedHomepageFeature extends LightningElement {
	@api featureHeading;
	@api featureBlurb;
	@api featureThumb;
	thumbnail;
	@api buttonText;
	@api buttonLink;
	@api linkTarget;
	@api sectionWidth;

	wrapperClass = 'featureCard';

	renderedCallback(){
	  this.wrapperClass = setWrapperClass(this.sectionWidth, 'featureCard');

		if(this.featureThumb){
		  fetchCommunityUrl({communityId: Id})
				.then( (result) => {
					console.log('fetch community url result: ', result);
					this.thumbnail = 'background-image: url("' + result + '/cms/delivery/media/' + this.featureThumb + '")';
				 }).catch(e => {
					 console.log('fetch community url error: ', e);
				 });
		}
	}

	get target(){
		return (this.linkTarget == 'Default') ? '' : '_blank';
 	}
}