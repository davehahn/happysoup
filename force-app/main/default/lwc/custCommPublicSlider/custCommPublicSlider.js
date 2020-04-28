/**
 * Created by Tim on 2020-04-24.
 */

import { LightningElement } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import swiperJS from '@salesforce/resourceUrl/SwiperJS';

export default class CustCommPublicSlider extends LightningElement {
	swipe;
  swipeInit = false;
  activeTitle = 'X18';
  activeLink = 'order-builder?c__recordId=recordIdTwo';
  config = {
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
	slides = [
	  {
	    title: '18 XTR',
	    id: 'order-builder?c__recordId=recordIdOne',
	    image: 'https://legend-marketing.s3.amazonaws.com/2020/misc/x18.png'
   },
   {
			title: 'X18',
			id: 'order-builder?c__recordId=recordIdTwo',
			image: 'https://legend-marketing.s3.amazonaws.com/2020/misc/x18.png'
		},
		{
			title: 'F19',
			id: 'order-builder?c__recordId=recordIdThree',
			image: 'https://legend-marketing.s3.amazonaws.com/2020/misc/x18.png'
	 },
 ];

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
			this.renderGlide();
		}).catch((error) => {
				this.error = error;
		});
	}

	renderGlide(){
		const swiper = document.createElement('div');
		swiper.className = 'swiper-container';
		this.template.querySelector('div.wrap').appendChild(swiper);

		const swipeWrapper = document.createElement('div');
		swipeWrapper.className = 'swiper-wrapper';
		this.template.querySelector('.swiper-container').appendChild(swipeWrapper);

		const slides = this.slides;
		slides.forEach((slide) => {
			const newSlide = document.createElement('div');
			newSlide.className = 'swiper-slide';
			newSlide.setAttribute('data-title', slide.title);
			newSlide.setAttribute('data-prodID', slide.id);
			this.template.querySelector('.swiper-wrapper').appendChild(newSlide);

			const boatWrapper = document.createElement('div');
			boatWrapper.className = 'boat';
			boatWrapper.setAttribute('data-prodID', slide.id);
			this.template.querySelector('div[data-prodID="' + slide.id + '"]').appendChild(boatWrapper);
			const newImage = document.createElement('img');
			newImage.setAttribute('src', slide.image);
			this.template.querySelector('div.boat[data-prodID="' + slide.id + '"]').appendChild(newImage);
  	})

		const pagination = document.createElement('div');
		pagination.className = 'swiper-pagination';
		this.template.querySelector('.swiper-container').appendChild(pagination);

		this.swipe = new Swiper(swiper, this.config);
		//this.swipe.slideTo(1);
		this.swipe.on('transitionEnd', () => {
		  let currSlide = this.swipe.realIndex;
		  console.log('swipe transition ended');
			console.log(currSlide);
			console.log(this.swipe.slides[currSlide].getAttribute('data-title'));
		  this.activeTitle = this.swipe.slides[currSlide].getAttribute('data-title');
			this.activeLink = this.swipe.slides[currSlide].getAttribute('data-prodID');
  	});
  }


}