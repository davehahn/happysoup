/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, api, wire } from 'lwc';
import Id from '@salesforce/community/Id';
import { NavigationMixin } from 'lightning/navigation';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';

export default class CommunitySharedCompanyLogo extends NavigationMixin(LightningElement) {
	@api companyLogo;
	@api companyName;
	companyLogoBg;
	companyLogoImg;

	communityHomePageRef;
	url;

	connectedCallback(){
	  this.communityHomePageRef = {
	    type: 'comm__namedPage',
	    attributes: {
	      name: 'Home'
     }
   };
   this[NavigationMixin.GenerateUrl](this.communityHomePageRef)
   	.then(url => {
			this.url = url;
			console.log('this communityHomePageRef url: ', this.url);
		});
 }

 navigateToPage( e ){
   e.preventDefault();
   e.stopPropagation;

   this[NavigationMixin.Navigate](this.communityHomePageRef);
 }

	renderedCallback(){
		if(this.companyLogo){
		  fetchCommunityDetails({communityId: Id})
		  	.then( (result) => {
		  	  console.log('fetch community url result: ', result);
		  	  this.companyLogoImg = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.companyLogo + '")';
				 }).catch(e => {
					 console.log('fetch community url error: ', e);
				 });
  	}
 	}
}