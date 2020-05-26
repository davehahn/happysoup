/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api, wire} from 'lwc';
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

  @wire(CurrentPageReference) pageRef;

	renderedCallback(){
		registerListener('motorSelection', this.handleMotorSelection, this);
	}

	get availableOptions(){

	  if(this.options){
	    let parentSku = null;
	    let options = this.options;
	    const keys = Object.keys(this.options);
			let optionDetails = [];
			const inputType = (this.selections === 'one') ? 'radio' : 'checkbox';

	    if('id' in options){
	      //single option details to array

	      if(this.subSection){
	        parentSku = options['id'];
	        options = this.recompose(options, this.subSection);
	        options = options[0];
       	}

	      let upgradePrice = 0;
	      if(parseInt(options['retailPrice']) === 0){
	      	upgradePrice = 'Included';
       	} else {
       	  if(this.showOptionPrice){
						upgradePrice = parseInt(options['retailPrice']);
					} else{
						upgradePrice = parseInt(options['retailPrice']) + parseInt(this.boatRetailPrice);
					}
					upgradePrice = new Intl.NumberFormat('en-CA', {
																				style: 'currency',
																				currency: 'CAD',
																				minimumFractionDigits: 0
																				}).format(upgradePrice);
        }

				let name = options['name'];
				const sku = options['id'];
				let km = null;
				let	rpm = null;
				let images = [];
				let blurb = null;
				let includedProducts = [];
				const init = (this.isInit) ? true : false;

				if('marketingContent' in options){
					let marketingContent = options['marketingContent'];
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
							 blurb = stripContent;
     			 	} else if(label === 'includedproducts'){
     			 	  includedProducts = stripContent.split("|");
         	 	} else if(label === 'customdisplayname'){
         	 	  name = stripContent;
            }
    	 		}
    		}

				optionDetails.push({
					'sku': sku,
					'name': name,
					'price': upgradePrice,
					'km': km,
					'rpm': rpm,
					'init': init,
					'inputType': inputType,
					'images': images,
					'blurb': blurb,
					'includedProducts': includedProducts,
					'parentSku': parentSku
				});
//				console.log('details: ', optionDetails);
				return optionDetails;

     	} else {
     	  //return 'multiple options';

     	  for(let option of options){
     	    if('id' in option){

     	      if(this.subSection){
     	        parentSku = option['id'];
							option = this.recompose(option, this.subSection);
							option = option[0];
						}

						let name = option['name'];
     	      const sku = option['id'];
     	      const selections = this.selections;
     	      let upgradePrice = 0;
     	      let km = null;
						let	rpm = null;
						let images = [];
						let blurb = null;
						let includedProducts = [];

						if('retailPrice' in option){
						  if(parseInt(option['retailPrice']) === 0){
								upgradePrice = 'Included';
							} else {
							  if(this.showOptionPrice){
									upgradePrice = parseInt(option['retailPrice']);
								} else{
									upgradePrice = parseInt(option['retailPrice']) + parseInt(this.boatRetailPrice);
								}
								upgradePrice = new Intl.NumberFormat('en-CA', {
																style: 'currency',
																currency: 'CAD',
																minimumFractionDigits: 0
																}).format(upgradePrice);
       				}
      			}
     	      else if('RetailUpgradeCost' in option){
     	        if(parseInt(option['RetailUpgradeCost']) === 0){
     	          upgradePrice = 'Included';
              } else {
                if(this.showOptionPrice){
									upgradePrice = parseInt(option['RetailUpgradeCost']);
								} else{
									upgradePrice = parseInt(option['RetailUpgradeCost']) + parseInt(this.boatRetailPrice);
								}
								upgradePrice = new Intl.NumberFormat('en-CA', {
																style: 'currency',
																currency: 'CAD',
																minimumFractionDigits: 0
																}).format(upgradePrice);
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
									blurb = unescape(stripContent);
        				} else if(label === 'includedproducts'){
									includedProducts = stripContent.split("|");
								} else if(label === 'customdisplayname'){
									name = stripContent;
							 	}
							}
						}

            optionDetails.push({
              'sku': sku,
							'name': name,
							'price': upgradePrice,
							'km': km,
							'rpm': rpm,
							'inputType': inputType,
							'images': images,
							'blurb': blurb,
							'includedProducts': includedProducts,
							'parentSku': parentSku
						});
          } else {
            //console.log('no id');
          }
        }
//				console.log('details: ', optionDetails);
        return optionDetails;
      }
   	}
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

	get optionClasses()
	{
		return (this.subSection) ? 'options_item hide' : 'options_item';
	}

	handleMotorSelection(detail){
	  let relatedOptions = this.template.querySelectorAll(`[data-parentpage="${detail.optionParentPage}"]`);
	  relatedOptions.forEach((option) => {
			console.log(option.classList);
			option.classList.add('hide');
			if(option.getAttribute('data-parentsku') === detail.optionSKU){
			  option.classList.remove('hide');
   		}
   	});
 	}
}
