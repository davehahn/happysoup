/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, api, wire } from 'lwc';
import Id from '@salesforce/community/Id';
import fetchCommunityUrl from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityUrl';

export default class CommunitySharedCompanyLogo extends LightningElement {
	@api companyLogo;
	@api companyName;
	companyLogoBg;
	companyLogoImg;

	renderedCallback(){
		if(this.companyLogo){
		  fetchCommunityUrl({communityId: Id})
		  	.then( (result) => {
		  	  console.log('fetch community url result: ', result);
		  	  this.companyLogoImg = 'background-image: url("' + result + '/cms/delivery/media/' + this.companyLogo + '")';
				 }).catch(e => {
					 console.log('fetch community url error: ', e);
				 });
  	}
 	}
}