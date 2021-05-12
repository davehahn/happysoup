/**
 * Created by Tim on 2021-04-07.
 */

import { LightningElement, api } from 'lwc';
import { setWrapperClass } from 'c/communitySharedUtils';

export default class CommunitySharedBoatListingIntro extends LightningElement {
	@api title;
	@api blurb;
	@api sectionWidth;

	wrapperClass = 'pageIntro';

	renderedCallback(){
		this.wrapperClass = setWrapperClass(this.sectionWidth, 'pageIntro');
 	}
}