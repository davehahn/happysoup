/**
 * Created by Tim on 2021-06-09.
 */

import { LightningElement, api } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, weeklyPayment, formatPrice, setWrapperClass } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';

export default class FactoryStoreLocationBanner extends LightningElement {
	@api headingLineOne;
	@api headingLineTwo;
	@api backgroundImage;

	@api teaserOneHeading;
	@api teaserOneDeck;
	@api teaserOneButtonText;
	@api teaserOneButtonLink;
	@api teaserOneLinkTarget;
	@api teaserOneBackground;

	@api teaserTwoHeading;
	@api teaserTwoDeck;
	@api teaserTwoButtonText;
	@api teaserTwoButtonLink;
	@api teaserTwoLinkTarget;
	@api teaserTwoBackground;

	@api teaserThreeHeading;
	@api teaserThreeDeck;
	@api teaserThreeButtonText;
	@api teaserThreeButtonLink;
	@api teaserThreeLinkTarget;
	@api teaserThreeBackground;

	@api moreInfoHeadingLineOne;
	@api moreInfoHeadingLineTwo;
	@api moreInfoButtonText;
	@api moreInfoButtonLink;
	@api moreInfoBackground;
	moreInfoBackgroundRef;

	@api sectionWidth;

	wrapperClass = "locationBanner";
	backgroundReference;

	allTeasers = [];

	connectedCallback(){
	  this.wrapperClass = setWrapperClass(this.sectionWidth, 'locationBanner');
//	  this.teaserOneHeading = this.teaserOneHeading;
	  if(this.backgroundImage){
			fetchCommunityDetails({communityId: Id})
				.then( (result) => {
					console.log('fetch community url result: ', result);
					this.backgroundReference = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.backgroundImage + '")';
					console.log('allTeasers 1: ', this.allTeasers);
					if(this.teaserOneHeading){
					  const backgroundRef = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.teaserOneBackground + '")';
					  const target = (this.teaserOneLinkTarget == 'Default') ? '' : '_blank';
						this.allTeasers.push({
							'heading': this.teaserOneHeading,
							'deck': this.teaserOneDeck,
							'buttonText': this.teaserOneButtonText,
							'buttonLink': this.teaserOneButtonLink,
							'buttonTarget': target,
							'background': backgroundRef
      			});
     			}
					console.log('allTeasers 2: ', this.allTeasers);
     			if(this.teaserTwoHeading){
						const backgroundRef = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.teaserTwoBackground + '")';
						const target = (this.teaserTwoLinkTarget == 'Default') ? '' : '_blank';
						this.allTeasers.push({
							'heading': this.teaserTwoHeading,
							'deck': this.teaserTwoDeck,
							'buttonText': this.teaserTwoButtonText,
							'buttonLink': this.teaserTwoButtonLink,
							'buttonTarget': target,
							'background': backgroundRef
						});
					}
					console.log('allTeasers 3: ', this.allTeasers);
					if(this.teaserThreeHeading){
						const backgroundRef = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.teaserThreeBackground + '")';
						const target = (this.teaserThreeLinkTarget == 'Default') ? '' : '_blank';
						this.allTeasers.push({
							'heading': this.teaserThreeHeading,
							'deck': this.teaserThreeDeck,
							'buttonText': this.teaserThreeButtonText,
							'buttonLink': this.teaserThreeButtonLink,
							'buttonTarget': target,
							'background': backgroundRef
						});
					}
				console.log('teasers: ', this.allTeasers);

				if(this.moreInfoBackground){
					  const backgroundRef = 'background-image: url("' + result.siteUrl + '/cms/delivery/media/' + this.moreInfoBackground + '")';
					  this.moreInfoBackgroundRef = backgroundRef;
    		}
			 }).catch(e => {
				 console.log('fetch community url error: ', e);
			 });
		}
 	}

}