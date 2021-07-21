/**
 * Created by Tim on 2021-04-26.
 */

import { LightningElement, wire, api } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, weeklyPayment, formatPrice, setWrapperClass, convertLength } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';

import initMethod from '@salesforce/apex/FactoryStore_MCWrapperController.initMethod';

export default class FactoryStoreCmsContentList extends LightningElement {
	@api contentType;
	@api topic;

	@api sectionWidth;

	galleryLoaded = false;
	galleryWrapperClass = 'gallery gallery--loading';
	photoGalleryClass = 'photoGallery';
	overlayClass = 'photoOverlay hidden';
	isDefaultContentType = false;
	imageToShow;
	@api content;

	connectedCallback(){
	  if(this.contentType !== 'default'){
	    initMethod({contentType: this.contentType, getTopics: this.topic})
	    	.then( (data) => {
	    	  console.log('get ' + this.contentType, data);
					this.content = data;
					this.galleryFound();
      	}).catch(e => {
					console.log('fetch series error:', e);
			 });
   	} else {
   	  if(this.content.length > 0){
   	    this.isDefaultContentType = true;
   	    this.galleryFound();
   	    this.photoGalleryClass = 'photoGallery photoGallery--default';
      }
    }
 	}

   galleryFound(){
     console.log('in galleryFound');
     this.galleryWrapperClass = setWrapperClass(this.sectionWidth, 'gallery');
     console.log('this.galleryWrapperClass', this.galleryWrapperClass);
     this.galleryLoaded = true;
   }

   triggerOverlay( e ){
     e.preventDefault();

     let image = e.currentTarget.href;
     this.imageToShow = image;
     this.overlayClass = 'photoOverlay open';

   }

   closeOverlay( e ){
     console.log(e.target.dataset.id);
     if(e.target.dataset.id !== 'image'){
       this.overlayClass = 'photoOverlay hidden';
     }
   }

}