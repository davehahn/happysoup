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

export {
	getTestimonials,
	stringy,
	stripParentheses,
	rewriteMotorName,
	rewriteTrailerName
}