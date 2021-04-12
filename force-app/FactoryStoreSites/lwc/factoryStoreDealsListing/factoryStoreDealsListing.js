/**
 * Created by Tim on 2021-04-08.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { getDeals, stringy } from 'c/factoryStoreUtils';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import swiperJS from '@salesforce/resourceUrl/SwiperJS';

export default class FactoryStoreDealsListing extends LightningElement {
	@api numberToShow;
	@api layoutView;
	@api orderBy;

	swipe;
	dealsInit = false;
	config = {
		init: false,
		slidesPerView: 1,
		initialSlide: 0,
		centeredSlides: true,
		spaceBetween: 1,
		breakpoints: {
		},
		pagination: {
			el: '.swiper-pagination',
			clickable: true,
		},
	};

	@track deals;

	renderedCallback()
	{
	   if(this.layoutView === 'Slideshow'){
	    	if(this.dealsInit){
						return;
				 }
				 this.dealsInit = true;
				 Promise.all([
						loadScript( this, swiperJS + '/swiper.min.js'),
						loadStyle( this, swiperJS + '/swiper.min.css')
				 ]).then(()=>{
				   console.log('swiper loaded');
				   getDeals(this.numberToShow).then((result) => {
				     console.log('found deals');
				     console.log('result', result);
				     this.deals = result;
						 this.renderSwiper();
       			}).catch(e => {
       				console.log('error');
          	});
					}).catch((error) => {
							this.error = error;
					});
		 } else {
		   if(this.dealsInit){
					return;
			 }
			 this.dealsInit = true;
			 console.log('set deals for list view');
			 getDeals(this.numberToShow).then((result) => {
				 console.log('found deals');
				 console.log('result', result);
				 this.deals = result;
				}).catch(e => {
						console.log('error');
				});
		 }
	}

	get showAsList(){
		return (this.layoutView === 'List') ? true : false;
 	}
 	get showAsSlideshow(){
 	  return (this.layoutView === "Slideshow") ? true : false;
  }

  renderSwiper(){
    console.log('start swiper');
		const swiper = document.createElement('div');
		swiper.className = 'swiper-container';
		this.template.querySelector('div.dealsSwiper').appendChild(swiper);

		const swipeWrapper = document.createElement('div');
		swipeWrapper.className = 'swiper-wrapper';
		this.template.querySelector('.swiper-container').appendChild(swipeWrapper);

		const slides = JSON.parse(JSON.stringify(this.deals));
		slides.forEach((slide) => {
			const newSlide = document.createElement('div');
			newSlide.className = 'swiper-slide';
			newSlide.setAttribute('data-title', slide.data.DealName);
			newSlide.setAttribute('data-dealID', slide.DataId);
			this.template.querySelector('.swiper-wrapper').appendChild(newSlide);

			const dealWrapper = document.createElement('div');
			dealWrapper.className = 'deal';
			dealWrapper.setAttribute('data-dealID', slide.DataId);
			this.template.querySelector('div[data-dealID="' + slide.DataId + '"]').appendChild(dealWrapper);

			const newImage = document.createElement('img');
			newImage.setAttribute('src', slide.data.BannerGraphic);
			this.template.querySelector('div.deal[data-dealID="' + slide.DataId + '"]').appendChild(newImage);
		});

		const pagination = document.createElement('div');
		pagination.className = 'swiper-pagination';
		this.template.querySelector('.swiper-container').appendChild(pagination);

		this.swipe = new Swiper(swiper, this.config);
		//this.swipe.slideTo(1);
		this.swipe.on('init', () => {
//			let currSlide = this.swipe.realIndex;
//			this.activeTitle = this.swipe.slides[currSlide].getAttribute('data-title');
//			this.activeLink = this.swipe.slides[currSlide].getAttribute('data-prodID');
		});
		this.swipe.init();
		this.swipe.on('transitionEnd', () => {
			let currSlide = this.swipe.realIndex;
			this.activeTitle = this.swipe.slides[currSlide].getAttribute('data-title');
			this.activeLink = this.swipe.slides[currSlide].getAttribute('data-dealID');
		});
	}
}