/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, wire, track} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners} from 'c/pubsub';
import { loadStyle } from 'lightning/platformResourceLoader';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';

export default class CustCommOrderOptions extends LightningElement {
  @api optionsTitle;
  @api selections;
  @api selectionScope;
  @api options;
  @api subSection;
  @api boatRetailPrice;
  @api isInit;
  @api page;
  @api parentPage;
  @api showOptionPrice;
  @api triggerUiChange;
  @api addons;
  @api layoutType;
  @api groupingName;

	@track swatchInfo = {
	  'name': '',
	  'price': '',
	  'blurb': ''
 	};

  @wire(CurrentPageReference) pageRef;

	renderedCallback(){
		registerListener('motorSelection', this.handleMotorSelection, this);
	}

	get availableOptions(){

	  if(this.options){

	    let options = this.options;

	    const keys = Object.keys(this.options);

			if('id' in options){
	      //single option details to array
	      const init = (this.isInit) ? true : false;
	      const parsedOption =  this.parseOption(options, init);
				return parsedOption;
     	} else {
     	  //return 'multiple options';
     	  let combinedOptions = [];
     	  options.forEach((option, index) => {
     	    if('id' in option){
     	      let init = (this.isInit && index === 0) ? true : false;
						const parsedOption = this.parseOption(option, init);
						combinedOptions.push(parsedOption[0]);
					} else {
						//console.log('no id');
					}
        });
//     	  for(let option of options){
//     	    if('id' in option){
//     	      const parsedOption = this.parseOption(option);
//     	      combinedOptions.push(parsedOption[0]);
//          } else {
//            //console.log('no id');
//          }
//        }
        return combinedOptions;
      }
   	}
 	}

	parseOption(option, init){
	  let parentSku = null;
	  let optionDetails = [];
		const inputType = (this.selections === 'one') ? 'radio' : 'checkbox';

		if(this.subSection){
			parentSku = option['id'];
			option = this.recompose(option, this.subSection);
			option = option[0];
		}

		let name = option['name'];
		const sku = option['id'];
		let km = null;
		let	rpm = null;
		let images = [];
		let blurb = null;
		let swatch = null;
		let includedProducts = [];


		const retailPrice = ('retailPrice' in option) ? parseInt(option['retailPrice']) : (('RetailUpgradeCost' in option) ? parseInt(option['RetailUpgradeCost']) : '');
		let displayPrice = 0;
		if(this.showOptionPrice){
			displayPrice = retailPrice;
		} else{
			if(parseInt(retailPrice) !== 0){
				displayPrice = retailPrice + parseInt(this.boatRetailPrice);
			}
		}

		if('marketingContent' in option){
			let marketingContent = option['marketingContent'];
			for(const mc of marketingContent){
				const label = mc['label'].toLowerCase();
				const origContent = mc['content'];
				const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
				if(label === 'km'){
					km = stripContent;
				} else if(label === 'rpm'){
					rpm = stripContent;
				} else if(label === 'images'){
					const imageObjects = stripContent.split("|").map(pair => pair.split(":"));
					imageObjects.forEach(([key,value]) => {
						images.push({
							'imageType': key,
							'imageURL': value,
						});
					});
				} else if(label === 'blurb'){
					 blurb = this.decodeHtml(stripContent);
				} else if(label === 'includedproducts'){
					includedProducts = stripContent.split("|");
				} else if(label === 'customdisplayname'){
					name = stripContent;
				} else if(label === 'swatch'){
					swatch = stripContent;
    		}
			}
		}

		optionDetails.push({
			'sku': sku,
			'name': name,
			'retailPrice': retailPrice,
			'displayPrice': displayPrice,
			'km': km,
			'rpm': rpm,
			'init': init,
			'inputType': inputType,
			'images': images,
			'blurb': blurb,
			'includedProducts': includedProducts,
			'parentSku': parentSku,
			'swatch': swatch
		});
//				console.log('details: ', optionDetails);
		return optionDetails;
 	}

 	get hasOptionsTitle(){
// 	  console.log('optionsTitle: ', this.optionsTitle);
 	  return (typeof this.optionsTitle !== 'undefined') ? true : false;
  }

  recompose(obj,string){
			var parts = string.split('.');
			var newObj = obj[parts[0]];
			if(parts[1]){
					parts.splice(0,1);
					var newString = parts.join('.');
					return this.recompose(newObj,newString);
			}
			return newObj;
	};

	decodeHtml(html) {
		var txt = document.createElement("textarea");
		txt.innerHTML = html;
		return txt.value;
  }

	get optionClasses()
	{
		return (this.subSection) ? 'options_item hide' : 'options_item';
	}

	handleMotorSelection(detail){
	  console.log('motor event fired');
	  let relatedOptions = this.template.querySelectorAll(`[data-parentpage="${detail.optionParentPage}"]`);
	  relatedOptions.forEach((option) => {
			option.classList.add('hide');
			if(option.getAttribute('data-parentsku') === detail.optionSKU){
			  option.classList.remove('hide');
   		}
   	});
 	}

 	handleSwatchChange(event){
 	  console.log('event detail: ', event.detail);
 	  const optionList = this.template.querySelector('.options_list');
 	  console.log(optionList.offsetHeight);
 	  console.log(optionList.offsetHeight + event.detail);
 	  optionList.style.marginBottom = event.detail + 'px';
  }

}
