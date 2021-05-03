/**
 * Created by Tim on 2021-05-03.
 */

import { LightningElement, api, track, wire } from 'lwc';
import Id from '@salesforce/community/Id';
import getManagedContentByContentKeys from '@salesforce/apex/CommSharedMC_Controller.getManagedContentByContentKeys';

export default class CommunitySharedCompanyLogo extends LightningElement {
	@api companyLogo;
	@track companyLogoBg;

	renderedCallback(){
		if(this.companyLogo){
		  getManagedContentByContentKeys({ communityId: Id, managedContentIds: this.companyLogo, pageParam: 0, pageSize: 1, language: 'en_US', managedContentType: 'cms_image', showAbsoluteUrl: false })
				.then( (result) => {
					this.companyLogoBg = 'background-image: url("' + result.items[0].contentNodes.source.url + '")';
					console.log('result: ', result);
				}).catch(e => {
						console.log('error: ', e);
				});
  	}
 	}
}