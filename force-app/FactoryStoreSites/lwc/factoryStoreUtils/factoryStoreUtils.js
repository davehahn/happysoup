/**
 * Created by Tim on 2021-04-05.
 */

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import FactoryStoreGlobals from '@salesforce/resourceUrl/FactoryStoreGlobals';

const getTestimonials = (numToShow) => {
  //console.log('showTestimonials', numToShow);
	let testimonials = [];
 	let testimonialJSON = {
 	  "UserName": "User Lastman",
 	  "UserCity": "Mindemoya",
 	  "UserProvince": "ON",
 	  "UserPhoto": `${FactoryStoreGlobals + '/img/silhouette.png'}`,
 	  "UserTestimonial": "Morbi eget diam in risus finibus tempor vel id mi. Etiam aliquet sagittis dictum. Sed lacinia lobortis rhoncus. Cras vel elementum est. Praesent sit amet leo risus. Nunc vulputate velit a scelerisque facilisis. Suspendisse vestibulum urna eu eleifend condimentum. Nam ornare leo nulla, id tincidunt nisl tempor vitae. Curabitur in neque pharetra, blandit velit sit amet, hendrerit ligula. In tristique augue scelerisque scelerisque cursus. Sed eleifend enim sit amet tempor congue. Nulla ut sagittis tortor. Nam vitae ligula et lectus bibendum interdum vel at eros. Cras nisl metus, gravida sed viverra a, commodo id odio. In leo eros, eleifend et ligula eu, viverra pharetra mauris."
  }
  for(let i = 0; i < numToShow; ++i){
    testimonials[i] = testimonialJSON;
  }
  return testimonials;
}

const stringy = (payload) => {
  return JSON.stringify(payload);
}

const stripParentheses = (payload) => {
  return payload.replace(/ *\([^]*\) */g, "");
}

const rewriteMotorName = (payload) => {
  console.log('rewriteMotorName', payload);
  let replaceFourStroke = ['4S', 'SSHS', 'FourStroke'];
  let replacementFourStroke = '4-Stroke';

	for(let i = 0; i < replaceFourStroke.length; ++i){
		if(payload.indexOf(replaceFourStroke[i])){
			return payload.replace(replaceFourStroke[i], replacementFourStroke);
			break;
		} else{
			return false;
		}
 	}
}

const rewriteTrailerName = (payload) => {
  console.log(payload);
  let replaceTrailerName = ['Duv18TM', 'Dub22L'];
  let replacementTrailerName = ['Glide-on Trailer'];

 	for(let i = 0; i < replaceTrailerName.length; ++i){
		if(payload.indexOf(replaceTrailerName[i])){
			return replacementTrailerName[i];
			break;
		} else{
			return payload;
		}
	}
}

/*===================
┌─┐┌─┐┬  ┌─┐┬ ┬┬  ┌─┐┌┬┐┌─┐  ┬ ┬┌─┐┌─┐┬┌─┬ ┬ ┬  ┌─┐┌─┐┬ ┬┌┬┐┌─┐┌┐┌┌┬┐
│  ├─┤│  │  │ ││  ├─┤ │ ├┤   │││├┤ ├┤ ├┴┐│ └┬┘  ├─┘├─┤└┬┘│││├┤ │││ │
└─┘┴ ┴┴─┘└─┘└─┘┴─┘┴ ┴ ┴ └─┘  └┴┘└─┘└─┘┴ ┴┴─┘┴   ┴  ┴ ┴ ┴ ┴ ┴└─┘┘└┘ ┴
=====================*/
const weeklyPayment = (price, lang = 'en') => {
	let rate = 0;
	let total_payments = 0;
	if(price >= 23000){
		rate = 0.0599 / 52;
		total_payments = 1040;
	} else if(price >= 10000){
		rate = 0.0599 / 52;
		total_payments = 780;
	} else if(price >= 1000){
		//This should actually be >= 5000, but I need to figure out what to do with those that would come back as $0, and it's better to have a value greater than zero that can be dismissed as 'it's like $X/month, but you can't finance this one' rather than have it show it could be $0/week
		rate = 0.0799 / 52;
		total_payments = 364;
	}

	let weekly = price * ( rate / ( 1 - Math.pow( ( 1 + rate ), - total_payments ) ) );
			weekly = weekly.toFixed(0);
	return (lang === 'en') ? '$' + weekly.toLocaleString('en-CA') : weekly.toLocaleString('en-FR') + ' $';
}

const formatPrice = (price, round = false, lang = 'en') => {
	price = (round) ? price.toFixed(0) : price;
	return (lang === 'en') ? '$' + price.toLocaleString('en-CA') : price.toLocaleString('en-FR') + ' $';
}

export {
	getTestimonials,
	stringy,
	stripParentheses,
	rewriteMotorName,
	rewriteTrailerName,
	weeklyPayment,
	formatPrice
}