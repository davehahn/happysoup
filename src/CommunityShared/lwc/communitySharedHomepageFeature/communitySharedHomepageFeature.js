/**
 * Created by Tim on 2021-03-24.
 */

import { LightningElement, api, wire, track } from 'lwc';
import Id from '@salesforce/community/Id';
import getManagedContentByContentKeys from '@salesforce/apex/CommSharedMC_Controller.getManagedContentByContentKeys';

export default class CommunitySharedHomepageFeature extends LightningElement {
	@api featureHeading;
	@api featureBlurb;
	@api featureThumb;
	@track thumbnail;
	@api buttonText;
	@api buttonLink;

	renderedCallback(){
		if(this.featureThumb){
			getManagedContentByContentKeys({ communityId: Id, managedContentIds: this.featureThumb, pageParam: 0, pageSize: 1, language: 'en_US', managedContentType: 'cms_image', showAbsoluteUrl: false })
				.then( (result) => {
					this.thumbnail = 'background-image: url("' + result.items[0].contentNodes.source.url + '")';
					console.log('result: ', result);
				}).catch(e => {
						console.log('error: ', e);
				});
		}
	}
}