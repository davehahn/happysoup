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

	get availableOptions(){
	  console.log('here');
	  if(this.options){
	    const options = this.options;
	    const keys = Object.keys(this.options);
			let motorDetails = [];

	    if('id' in options){
	      //single option details to array
				const retailPrice = parseInt(options['retailPrice']) + parseInt(this.boatRetailPrice);
				const name = options['name'];
				const sku = options['id'];
				let km = null;
				let	rpm = null;

				if('marketingContent' in options){
					let marketingContent = options['marketingContent'];
					for(const mc of marketingContent){
					  const origContent = mc['content'];
						const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
						if(mc['label'] === 'KM'){
							km = stripContent;
      			} else if(mc['label'] === 'RPM'){
							rpm = stripContent;
        		}
    	 		}
    		}
				motorDetails.push({
					'sku': sku,
					'name': name,
					'price': retailPrice,
					'km': km,
					'rpm': rpm
				});
				console.log('details: ', motorDetails);
				return motorDetails;

     	} else {
     	  //return 'multiple options';
     	  for(const option of options){
     	    if('id' in option){
     	      const name = option['name'];
     	      const sku = option['id'];
     	      let retailPrice = 0;
     	      let km = null;
						let	rpm = null;
     	      if('RetailUpgradeCost' in option){
							retailPrice = parseInt(option['RetailUpgradeCost']) + parseInt(this.boatRetailPrice);
            }
						if('marketingContent' in option){
							let marketingContent = option['marketingContent'];
							for(const mc of marketingContent){
								const origContent = mc['content'];
								const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
								if(mc['label'] === 'KM'){
									km = stripContent;
								} else if(mc['label'] === 'RPM'){
									rpm = stripContent;
								}
							}
						}
            motorDetails.push({
              'sku': sku,
							'name': name,
							'price': retailPrice,
							'km': km,
							'rpm': rpm
						});
          } else {
            //console.log('no id');
          }
        }
        console.log('details: ', motorDetails);
        return motorDetails;
      }
   	}
 	}
}
