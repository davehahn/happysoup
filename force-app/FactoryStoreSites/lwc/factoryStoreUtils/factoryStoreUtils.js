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

export {
	getTestimonials,
	stringy
}