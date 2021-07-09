/**
 * Created by Tim on 2021-07-08.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, weeklyPayment, formatPrice, setWrapperClass } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';

export default class FactoryStoreSeriesListing extends NavigationMixin(LightningElement) {

	@api sectionWidth;
	@api seriesName;
	@api seriesBlurb;

	@api seriesButtonText;
	@api seriesButtonLink;
	seriesButtonLinkRewrite;

	wrapperClass = 'series';

	connectedCallback(){
	  fetchCommunityDetails({communityId: Id})
	  .then( (result) => {
	  	this.seriesButtonLinkRewrite = result.siteUrl + '/s' + this.seriesButtonLink;
		}).catch(e => {
			 console.log('fetch community url error: ', e);
	 	});
 }

	renderedCallback(){
	  this.wrapperClass = setWrapperClass(this.sectionWidth, 'series');
 	}

 @wire(CurrentPageReference) pageRef;

	get fullSeriesName(){
		let series = this.seriesName;
		return (series.toLowerCase().indexOf('series') !== -1) ? series : series + '-Series';
 }

 get seriesClass(){
	 let series = this.seriesName.toLowerCase();
	 return (series.indexOf('series') !== -1) ? series : series + '-series';
 }

}