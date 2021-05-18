/**
 * Created by Tim on 2021-05-17.
 */

import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { setWrapperClass } from 'c/communitySharedUtils';

export default class FactoryStoreOverlayWithLeadForm extends LightningElement {
	recordId;
	boatName;
	wrapperClass = 'overlay';

	@api introHeading;
	@api introBlurb;
	@api sectionWidth;

	@wire(CurrentPageReference) pageRef;

	renderedCallback(){
	  registerListener('openOverlay', this.handleOpenOverlay, this);
 }

 handleOpenOverlay(detail){
   console.log('handleOpenOverlay');
   console.log('recordId: ', detail.recordId);
   this.recordId = detail.recordId;
   this.boatName = detail.boatName;
   this.wrapperClass = setWrapperClass(this.sectionWidth, 'overlay open');
 }

 handleCloseOverlay(){
   this.wrapperClass = setWrapperClass(this.sectionWidth, 'overlay closed');
 }
}