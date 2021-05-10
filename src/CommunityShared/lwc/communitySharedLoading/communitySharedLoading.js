/**
 * Created by Tim on 2021-05-04.
 */

import { LightningElement, api } from 'lwc';
import LOADINGICON from '@salesforce/resourceUrl/LegendLoadingIndicator2017';

export default class CommunitySharedLoading extends LightningElement {
	loadingIcon = LOADINGICON;

	@api overlay = false;
	@api overlayOpacity = 1;
	overlayStyling;

	renderedCallback(){
	  this.overlayStyling = (this.overlay) ? 'background-color: rgba(255, 255, 255, ' + this.overlayOpacity + ')' : '';
 }

}