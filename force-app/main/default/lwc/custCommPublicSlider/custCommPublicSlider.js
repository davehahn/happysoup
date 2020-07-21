/**
 * Created by Tim on 2020-04-24.
 */

import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import swiperJS from '@salesforce/resourceUrl/SwiperJS';
import fetchBoats from '@salesforce/apex/OnlineBoatReservation_Controller.fetchBoats';

export default class CustCommPublicSlider extends NavigationMixin(LightningElement) {
	//@wire( fetchBoats ) boats;
	@track boats;
	@track boatsErrors;
	swipe;
  swipeInit = false;
  activeTitle;
  activeLink;
  config = {
    init: false,
    slidesPerView: 1,
		initialSlide: 1,
		centeredSlides: true,
		spaceBetween: 1,
		breakpoints: {
			 640: {
			    slidesPerView: 1.5,
    	 },
    	 1024: {
					slidesPerView: 1.75,
			 }
		},
		pagination: {
			el: '.swiper-pagination',
			clickable: true,
		},
	};

	renderedCallback()
	{
	  if(this.swipeInit){
	    return;
   }
   this.swipeInit = true;

   Promise.all([
     	loadScript( this, swiperJS + '/swiper.min.js'),
			loadStyle( this, swiperJS + '/swiper.min.css')
   ]).then(()=>{
     	fetchBoats()
     		.then(result => {
     		  console.log('result:', result);
     		  this.boats = result;
     		  this.renderGlide();
       	}).catch(error => {
       	  console.log('error: ' + error );
					this.boatsErrors = error;
       	});
		}).catch((error) => {
				this.error = error;
		});
	}

	navToBoat( event )
	{
		event.preventDefault();

		let page = 'order-builder',
				params = {
					c__recordId: event.target.dataset.recordId
				};

		this.navigateToCommunityPage( page, params );
	}

	navigateToCommunityPage( pageName, params )
	{
		console.log( pageName );
		console.log( params );
		this[NavigationMixin.Navigate]({
				type: 'comm__namedPage',
				attributes: {
						pageName: pageName
				},
				state: params
		});
	}

	renderGlide(){
		const swiper = document.createElement('div');
		swiper.className = 'swiper-container';
		this.template.querySelector('div.wrap').appendChild(swiper);

		const swipeWrapper = document.createElement('div');
		swipeWrapper.className = 'swiper-wrapper';
		this.template.querySelector('.swiper-container').appendChild(swipeWrapper);

		const slides = this.boats;
		console.log('slides:', slides);
		slides.forEach((slide) => {
			const newSlide = document.createElement('div');
			newSlide.className = 'swiper-slide';
			newSlide.setAttribute('data-title', slide.name);
			newSlide.setAttribute('data-prodID', slide.id);
			this.template.querySelector('.swiper-wrapper').appendChild(newSlide);

			const boatWrapper = document.createElement('div');
			boatWrapper.className = 'boat';
			boatWrapper.setAttribute('data-prodID', slide.id);
			this.template.querySelector('div[data-prodID="' + slide.id + '"]').appendChild(boatWrapper);
			const newImage = document.createElement('img');
			newImage.setAttribute('src', slide.imageURL);
			this.template.querySelector('div.boat[data-prodID="' + slide.id + '"]').appendChild(newImage);
  	})

		const pagination = document.createElement('div');
		pagination.className = 'swiper-pagination';
		this.template.querySelector('.swiper-container').appendChild(pagination);

		this.swipe = new Swiper(swiper, this.config);
		//this.swipe.slideTo(1);
		this.swipe.on('init', () => {
			let currSlide = this.swipe.realIndex;
			this.activeTitle = this.swipe.slides[currSlide].getAttribute('data-title');
			this.activeLink = this.swipe.slides[currSlide].getAttribute('data-prodID');
		});
		this.swipe.init();
		this.swipe.on('transitionEnd', () => {
		  let currSlide = this.swipe.realIndex;
		  this.activeTitle = this.swipe.slides[currSlide].getAttribute('data-title');
			this.activeLink = this.swipe.slides[currSlide].getAttribute('data-prodID');
  	});
  }


}
