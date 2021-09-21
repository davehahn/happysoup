/**
 * Created by Tim on 2021-04-05.
 */

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import LANG from '@salesforce/i18n/lang';
import CommunitySharedResources from '@salesforce/resourceUrl/CommunitySharedResources';

const getTestimonials = (numToShow) => {
  //console.log('showTestimonials', numToShow);
	let testimonials = [];
 	let testimonialJSON = {
 	  "UserName": "User Lastman",
 	  "UserCity": "Mindemoya",
 	  "UserProvince": "ON",
 	  "UserPhoto": `${CommunitySharedResources + '/img/silhouette.png'}`,
 	  "UserTestimonial": "Morbi eget diam in risus finibus tempor vel id mi. Etiam aliquet sagittis dictum. Sed lacinia lobortis rhoncus. Cras vel elementum est. Praesent sit amet leo risus. Nunc vulputate velit a scelerisque facilisis. Suspendisse vestibulum urna eu eleifend condimentum. Nam ornare leo nulla, id tincidunt nisl tempor vitae. Curabitur in neque pharetra, blandit velit sit amet, hendrerit ligula. In tristique augue scelerisque scelerisque cursus. Sed eleifend enim sit amet tempor congue. Nulla ut sagittis tortor. Nam vitae ligula et lectus bibendum interdum vel at eros. Cras nisl metus, gravida sed viverra a, commodo id odio. In leo eros, eleifend et ligula eu, viverra pharetra mauris."
  }
  for(let i = 0; i < numToShow; ++i){
    testimonials[i] = testimonialJSON;
  }
  return testimonials;
}

const getTestUser = () => {
	const Lead = {
	  'LeadSource': 'Online - Web',
	  'FirstName': 'Fistester',
	  'LastName': 'Lastmans',
	  'Email': 'flastman@legendboats.com',
	  'PostalCode': 'L5J2E9'
 }
 return Lead;
}

const stringy = (payload) => {
  return JSON.stringify(payload);
}

const gen8DigitId = () => {
  return Math.random().toString(36).substring(2, 10);
}

const stripParentheses = (payload) => {
  return payload.replace(/ *\([^]*\) */g, "");
}

const rewriteMotorName = (payload) => {
  let replaceFourStroke = ['4S', 'SSHS', 'FourStroke'];
  let replacementFourStroke = (renderEN()) ? '4-Stroke' : '4-Temps';

	for(let i = 0; i < replaceFourStroke.length; ++i){
		if(payload.indexOf(replaceFourStroke[i])){
			return payload.replace(replaceFourStroke[i], replacementFourStroke);
			break;
		} else{
			return payload;
		}
 	}
}

const rewriteTrailerName = (payload) => {
  console.log('trailer name payload: ', payload);
  let replaceTrailerName = 'Galv';
  let replacementTrailerName = 'Galvanized Glide-on Trailer';

	if(payload.indexOf(replaceTrailerName) > 0){
		return replacementTrailerName;
	} else{
		return (renderEN()) ? 'Glide-on Trailer' : 'Remorque «Glide-on»';
	}
}

const renderEN = () => {
  const lang = LANG;
    //  console.log('renderEN', lang);
      const options = ['en_US', 'en-US', 'en_CA', 'en-CA'];
    	return options.includes(lang) ? true : false;
}
const renderFR = () => {
  const lang = LANG;
    //  console.log('renderFR', lang);
    const options = ['fr', 'fr-CA', 'fr_CA'];
    	return options.includes(lang) ? true : false;
}

const decodeHTML = (html) => {
	let txt = new DOMParser().parseFromString(html, "text/html");
	return txt.documentElement.textContent;
}

/*===================
┌─┐┌─┐┬  ┌─┐┬ ┬┬  ┌─┐┌┬┐┌─┐  ┬ ┬┌─┐┌─┐┬┌─┬ ┬ ┬  ┌─┐┌─┐┬ ┬┌┬┐┌─┐┌┐┌┌┬┐
│  ├─┤│  │  │ ││  ├─┤ │ ├┤   │││├┤ ├┤ ├┴┐│ └┬┘  ├─┘├─┤└┬┘│││├┤ │││ │
└─┘┴ ┴┴─┘└─┘└─┘┴─┘┴ ┴ ┴ └─┘  └┴┘└─┘└─┘┴ ┴┴─┘┴   ┴  ┴ ┴ ┴ ┴ ┴└─┘┘└┘ ┴
=====================*/
const weeklyPayment = (price, lang = 'en') => {
	if(price){
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
    	let settings = {style: "currency", currency: 'CAD'};
    	if(lang === 'en'){
      	  return new Intl.NumberFormat('en-CA', {
          												style: 'currency',
          												currency: 'CAD',
          												minimumFractionDigits: 0
          												}).format(weekly);
       	} else {
       		return new Intl.NumberFormat('fr-CA', {
          												style: 'currency',
          												currency: 'CAD',
          												minimumFractionDigits: 0
          												}).format(weekly);
        }
 	}
}

const formatPrice = (price, round = false, lang = 'en') => {
  if(price){
    price = (round) ? price.toFixed(0) : price;
    	let settings = {style: "currency", currency: 'CAD'};
    	if(lang === 'en'){
    	  return new Intl.NumberFormat('en-CA', {
        												style: 'currency',
        												currency: 'CAD',
        												minimumFractionDigits: 0
        												}).format(price);
     	} else {
     		return new Intl.NumberFormat('fr-CA', {
        												style: 'currency',
        												currency: 'CAD',
        												minimumFractionDigits: 0
        												}).format(price);
      }
  }


}

const setWrapperClass = (width, additionalClassNames = null) => {
	if(width === 'Screen'){
		return additionalClassNames + ' fullWidth';
	} else if(width === 'Container'){
		return additionalClassNames;
	} else if(width === 'Wide'){
		return additionalClassNames + ' maxWidth';
	} else if(width === 'Average'){
		return additionalClassNames + ' maxWidth maxWidth--thin';
	} else if(width === 'Thin'){
		return additionalClassNames + ' maxWidth maxWidth--extraThin';
	} else if(width === 'Extra Thin'){
		return additionalClassNames + ' maxWidth maxWidth--ultraThin';
	}
}

const convertLength = ( value, truncateLengthTrailingZero = true) => {
  const baseValue = parseFloat( value ).toString();
  const baseArray = baseValue.split( '.' );

  const newFeet = (typeof baseArray[0] !== 'undefined' || baseArray[0] !== null) ? baseArray[0] + '&rsquo;' : '';
  let inches = null;
//  console.log('Covert Length Base Array: ', baseArray);
//  console.log('Covert Length Base Array[1]: ', baseArray[1]);
//  console.log('Covert Length Base Array[1] type: ', (typeof baseArray[1]));
  if((typeof baseArray[1] !== 'undefined') && (baseArray[1] !== null)){
    if(baseArray[1].substring(-1) === '0' && truncateLengthTrailingZero){
      inches = baseArray[1].substring( 0, -1);
    } else {
      inches = baseArray[1];
    }
  }
  const newInches = (typeof baseArray[1] !== 'undefined' && baseArray[1] !== null) ? inches + '&rdquo;' : '';
  return '<strong>' + newFeet + newInches + '</strong>';
}

const parseLocationName = (locationName) => {
	let name = locationName.replace('Legend Boats ', '');
	if(name === 'Sudbury'){
		name = 'Whitefish';
	}
	if((name.toLowerCase() === 'sainte marthe sur le lac') || (name.toLowerCase() === 'ste-marthe-sur-le-lac')){
		name = 'Montreal';
	}
	return name;
}

export {
	getTestimonials,
	getTestUser,
	stringy,
	stripParentheses,
	rewriteMotorName,
	rewriteTrailerName,
	weeklyPayment,
	formatPrice,
	renderEN,
	renderFR,
	decodeHTML,
	gen8DigitId,
	setWrapperClass,
	convertLength,
	parseLocationName
}
