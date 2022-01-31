/**
 * Created by Tim on 2021-09-17.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, weeklyPayment, formatPrice, setWrapperClass, convertLength, renderEN, renderFR } from 'c/communitySharedUtils';
import BANNER from '@salesforce/resourceUrl/FactoryStoreModelBanner';
import fetchSerialNumber from '@salesforce/apex/FactoryStore_InventoryController.fetchSerialNumber';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
//import fetchImages from '@salesforce/apex/FactoryStore_InventoryController.fetchImages';

export default class FactoryStoreUsedBoatDetails extends NavigationMixin(LightningElement) {

	@api recordId;
	@api sectionWidth;

	isEN = renderEN();
  	isFR = renderFR();

	bannerBg = 'background-image: url(' + BANNER + ')';

	displayRecordId;
	serial;

	serialDataLookupRunning = true;
	serialDataLoaded = false;
	resultEmpty = false;

	photoGallery;
	hasPhotoGallery = false;
	boatName;

	fullDescription;

	richTextGallery;

	serialWrapperClass = 'serial serial--loading';

	@wire(CurrentPageReference) pageRef;

 	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference){
	  console.log('fs used details recordID: ', this.recordId);
	  this.displayRecordId = this.recordId;
	}

	  @wire( fetchSerialNumber, { serialId: '$recordId' } )
    wiredFetchSerialNumber( { error, data } )
    {
      if( data )
      {
        console.log('this serial: ', data);
        if(data.length !== 0){
          this.serial = data;
  				this.recordFound();
        } else {
          this.resultEmpty();
        }
      }
      else if( error )
      {
        console.log('Ooops: ', error);
      }
    }

	recordFound(){
		console.log('Record FOUND!');
		console.log('serial: ', this.serial);
		this.serialDataLoaded = true;
		this.serialDataLookupRunning =  false;
		this.serialWrapperClass = setWrapperClass(this.sectionWidth, 'serial');
		this.boatName = stripParentheses(this.serial.Product_Name__c);
		this.fullDescription = this.serial.Description_Used__c;
		this.fullDescription = this.fullDescription.replace('%%START_GALLERY%%', '<div class="mini-gallery">');
		this.fullDescription = this.fullDescription.replace('%%END_GALLERY%%', '</div>');
//		fetchImages({serialNumber: this.serial})
//				.then( (images) => {
//					console.log('got images: ', images);
//					this.photoGallery = (images.MarketingImages.length > 0) ? images.MarketingImages : '';
//					this.hasPhotoGallery = (images.MarketingImages.length > 0) ? true : false;
//				}).catch(e => {
//				console.log('fetch images error:', e);
//		 });

		let details = {
				recordId: this.recordId,
				boatName: this.boatName,
				serialNumber: this.serial.Name,
				serialNumberId: this.serial.Id
			}
			console.log('Used details to send to form: ', details);
			fireEvent(this.pageRef, 'exposeUsedModelDetails', details);
	}

	get retailPrice(){
		return formatPrice(this.serial.RetailSalePrice__c, true);
	}

	resultEmpty(){
		console.log('hmmmm...');
		this.serialDataLookupRunning =  false;
		this.resultEmpty = true;
	}
}