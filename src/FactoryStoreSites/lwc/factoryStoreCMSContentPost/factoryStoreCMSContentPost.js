/**
 * Created by Tim on 2021-04-26.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import initMethod from '@salesforce/apex/FactoryStore_MCWrapperController.initMethod';
import basePath from '@salesforce/community/basePath';
import { decodeHTML } from 'c/communitySharedUtils';

export default class FactoryStoreCmsContentPost extends LightningElement {

  @track contentKey;
  @track post = '';

  @track postTitle;
  @track bannerGraphic;
  @track startDate;
  @track endDate;
  @track mainContent;
  @track clickToFullDetails = false;
  @track fullDetailsLink;

  baseDir = (basePath.includes('/s')) ? basePath.slice(0, -2) : basePath;

  @wire(CurrentPageReference) currentPageReference;

  get recordIdFromState(){
    let fullKey = (this.currentPageReference.attributes.contentKey) ? this.currentPageReference.attributes.contentKey : this.currentPageReference.attributes.urlAlias;

    const regex = /-MC[A-Z0-9]+$/;
    let keySegment = fullKey.match(regex);
    let isoKey = keySegment[0].replace('-', '');
		this.contentKey = isoKey;

		if(isoKey !== ''){
			const result = initMethod({ contentKey: isoKey })
					.then( (result) => {
						this.post = result[0];
						this.renderPost();
     			}).catch(e => {
							console.log('error: ', e);
					});
		} else {
			console.log('contentkey not set');
		}
  }

	renderedCallback(){
		if(this.contentKey === undefined){
			this.recordIdFromState;
 	 	}
 	}

 	renderPost(){
 	  const post = this.post;
 	  console.log('readable post: ', JSON.parse( JSON.stringify( post ) ) );
 	  this.postTitle = (post.title) ? post.title : 'Post Title Missing';
 	  this.bannerGraphic = (post.contentNodes.BannerGraphic.unauthenticatedUrl) ? 'background-image: url("' + this.baseDir + post.contentNodes.BannerGraphic.unauthenticatedUrl + '")' : 'Banner Graphic Missing';
 	  this.startDate = (post.contentNodes.StartDate.value) ? new Date(post.contentNodes.StartDate.value).toLocaleDateString() : 'Start Date Missing';
 	  this.endDate = (post.contentNodes.EndDate.value) ? new Date(post.contentNodes.EndDate.value).toLocaleDateString() : 'Ongoing';
 	  this.mainContent = (post.contentNodes.MainContent.value) ? decodeHTML(post.contentNodes.MainContent.value) : 'Main Content Missing';
 	  this.clickToFullDetails = (post.contentNodes.CampaignId.value) ? true : false;
 	  this.fullDetailsLink = (post.contentNodes.CampaignId.value) ? "https://www.legendboats.com/campaignDirect/" + post.contentNodes.CampaignId.value : '';
  }
}