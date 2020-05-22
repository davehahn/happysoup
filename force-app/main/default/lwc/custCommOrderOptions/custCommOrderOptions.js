/**
 * Created by Tim on 2020-04-22.
 */

import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import gothamFonts from '@salesforce/resourceUrl/GothamHTF';

export default class CustCommOrderOptions extends LightningElement {
  @api optionsTitle;
  @api selections;
  @api selectionScope;
  @api options;
  @api boatRetailPrice;
  @api isInit;
  @api page;

	get availableOptions(){

	  if(this.options){
	    const options = this.options;
	    const keys = Object.keys(this.options);
			let optionDetails = [];
			const inputType = (this.selections === 'one') ? 'radio' : 'checkbox';
			const strToReplace = ['Duv22L', 'Duv22L Galv'];
			const replaceWith = ['Black Powder Coated Trailer', 'Galvanized Trailer'];
	    if('id' in options){
	      //single option details to array
				let upgradePrice = parseInt(options['retailPrice']) + parseInt(this.boatRetailPrice);
				upgradePrice = new Intl.NumberFormat('en-CA', {
        							  							style: 'currency',
        							  							currency: 'CAD',
        							  							minimumFractionDigits: 0
        							  							}).format(upgradePrice);
				const name = options['name'];
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
				});
//				console.log('details: ', optionDetails);
				return optionDetails;

     	} else {
     	  //return 'multiple options';
     	  for(const option of options){
     	    if('id' in option){
     	      const name = option['name'];
     	      const sku = option['id'];
//     	      console.log('sku: ', sku);
     	      const selections = this.selections;
     	      let upgradePrice = 0;
     	      let km = null;
						let	rpm = null;
						let images = [];
						let blurb = null;
						let includedProducts = [];

						if('retailPrice' in option){
						  upgradePrice = parseInt(option['retailPrice']) + parseInt(this.boatRetailPrice);
							upgradePrice = new Intl.NumberFormat('en-CA', {
															style: 'currency',
															currency: 'CAD',
															minimumFractionDigits: 0
															}).format(upgradePrice);
      			}
     	      else if('RetailUpgradeCost' in option){
							upgradePrice = parseInt(option['RetailUpgradeCost']) + parseInt(this.boatRetailPrice);
							upgradePrice = new Intl.NumberFormat('en-CA', {
							  							style: 'currency',
							  							currency: 'CAD',
							  							minimumFractionDigits: 0
							  							}).format(upgradePrice);
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

 	handleOptionView(event){
 	  const optionDetails = event.detail;
 	  //console.log(JSON.parse(JSON.stringify(optionDetails)));
		const updateEvent = new CustomEvent('updateoptionview', {
			detail: optionDetails
  	});
  	this.dispatchEvent(updateEvent);
  }
}
