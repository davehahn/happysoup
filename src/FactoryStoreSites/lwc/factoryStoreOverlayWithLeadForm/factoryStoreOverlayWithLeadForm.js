/**
 * Created by Tim on 2021-05-17.
 */

import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import Id from '@salesforce/community/Id';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';
import { setWrapperClass } from 'c/communitySharedUtils';

export default class FactoryStoreOverlayWithLeadForm extends LightningElement {
	recordId;
	boatName;
	serialNumber = "N/A";
	wrapperClass = 'overlay';

	@api introHeading;
	@api introBlurb;
	@api sectionWidth;
	@api campaignId;

	leadFormName;
	locationName;

	@wire(CurrentPageReference) pageRef;

	@wire( fetchCommunityDetails, {communityId: Id} )
		wiredFetchCommunityDetails( { error, data } )
		{
			if( data )
			{
				this.locationName = data.name;
			}
			else if( error )
			{
				console.log('fetch community error: ', error);
			}
		}

	renderedCallback(){
	  registerListener('openOverlay', this.handleOpenOverlay, this);
 }

 handleOpenOverlay(detail){
   console.log('handleOpenOverlay');
   console.log('recordId: ', detail.recordId);
   this.recordId = detail.recordId;
   this.boatName = detail.boatName;
   this.serialNumber = detail.serialNumber;
   this.leadFormName = this.boatName + ' - Lead Form';
   this.wrapperClass = setWrapperClass(this.sectionWidth, 'overlay open');
 }

 handleCloseOverlay(){
   this.wrapperClass = setWrapperClass(this.sectionWidth, 'overlay closed');
 }
}