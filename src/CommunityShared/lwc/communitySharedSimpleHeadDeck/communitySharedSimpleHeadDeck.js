/**
 * Created by Tim on 2021-05-10.
 */

import { LightningElement, api } from 'lwc';
import { setWrapperClass } from 'c/communitySharedUtils';

export default class CommunitySharedSimpleHeadDeck extends LightningElement {
	@api introTitle;
	@api headingLevel;
	@api headingSize;
	@api introBlurb;
	@api sectionWidth;

	wrapperClass = 'simpleIntro';

	renderedCallback(){
	  this.wrapperClass = setWrapperClass(this.sectionWidth, 'simpleIntro');
 	}

	get fullIntroTitle(){
		return this.headingOpenTag + this.introTitle + this.headingCloseTag;
 	}

	get headingOpenTag(){
	  console.log('heading size: ', this.headingSize.toLowerCase());
		let tag = '<h1 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
		if(this.headingLevel === 'h2'){
			tag = '<h2 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
  	} else if(this.headingLevel === 'h3'){
  		tag = '<h3 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
  	} else if(this.headingLevel === 'h4'){
			tag = '<h4 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
		} else if(this.headingLevel === 'h5'){
			tag = '<h5 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
		} else if(this.headingLevel === 'h6'){
			tag = '<h6 class="simpleIntro__heading heading heading--' + this.headingSize.toLowerCase() + '">';
		}

  	return tag;
 	}

 	get headingCloseTag(){
		let tag = '</h1>';
		if(this.headingLevel === 'h2'){
			tag = '</h2>';
		} else if(this.headingLevel === 'h3'){
			tag = '</h3>';
		} else if(this.headingLevel === 'h4'){
			tag = '</h4>';
		} else if(this.headingLevel === 'h5'){
			tag = '</h5>';
		} else if(this.headingLevel === 'h6'){
			tag = '</h6>';
		}

		 return tag;
	}
}