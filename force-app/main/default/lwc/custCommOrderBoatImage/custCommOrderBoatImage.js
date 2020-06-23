/**
 * Created by Tim on 2020-04-23.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners} from 'c/pubsub';

export default class CustCommOrderBoatImage extends LightningElement {
    @api size;
    @api motorDetails;
    @api page;
    @api marketingContent;

    @track motorImage;
    @track canvasImage;
    @track hasCanvasImage = false;
    @track transomImage;
		@track hasTransomImage = false;
		@track electronicsImage;
		@track hasElectronicsImage = false;
    @track boatImage;
    @track defaultImage;

		@wire(CurrentPageReference) pageRef;

		connectedCallback(){
			registerListener('motorSelection', this.handleImageChange, this);
			registerListener('traileringSelection', this.handleImageChange, this);
			registerListener('electronicsSelection', this.handleImageChange, this);
		}
		renderedCallback(){
			//set default image
			if(this.marketingContent){
				let marketingContent = this.marketingContent;
				for(const mc of marketingContent){
					const label = mc['label'].toLowerCase();
					const origContent = mc['content'];
					const stripContent = origContent.replace(/(<([^>]+)>)/ig,"");
					if(label === 'images'){
						const imageObjects = stripContent.split("|").map(pair => pair.split(":"));
						imageObjects.forEach(([key,value]) => {
						  if(this.page === 'performance'){
								if(key === 'backRight'){
								  this.defaultImage = 'https://' + value;
									this.boatImage = 'https://' + value;
								}
							} else if(this.page === 'trailering' || this.page === 'electronics'){
								if(key === 'backLeft'){
								  this.defaultImage = 'https://' + value;
									this.boatImage = 'https://' + value;
								}
							}
						});
					}
				}
			}

  	}

		handleImageChange(detail){
		  console.log('detail.optionName', detail.optionName);
		  console.log('detail.optionImage', JSON.stringify(detail.optionImage));
		  console.log('detail.optionImage', detail.optionImage);
		  console.log('detail.addToComposite', detail.addToComposite);

			if(detail.optionImage.length > 0){
				for(let image of detail.optionImage){
					if(this.page === 'performance'){
						if(image.imageType === 'backRight'){
							this.motorImage = 'https://' + image.imageURL;
						}
					}

					if(this.page === 'trailering' || this.page === 'electronics'){
						if(image.imageType === 'backLeft'){
							console.log('has back left');
							if(detail.optionName === 'Add Bow To Stern Cover'){
							  if(this.page !== 'electronics'){
							  	this.canvasImage = (detail.addToComposite) ? 'https://' + image.imageURL : '';
							  	this.hasCanvasImage = (detail.addToComposite) ? true : false;
								}
						 	} else if(detail.optionName === 'Transom Saver - Motor Support'){
								this.transomImage = (detail.addToComposite) ? 'https://' + image.imageURL : '';
								this.hasTransomImage = (detail.addToComposite) ? true : false;
							} else if(detail.optionName === 'Galvanized Trailer'){
							  console.log('this.boatImage', this.boatImage);
								this.boatImage = 'https://' + image.imageURL;
								console.log('this.boatImage', this.boatImage);
							} else if(detail.optionName === 'Terrova 55 Tech Package'){
							  if(this.page !== 'trailering'){
									this.electronicsImage = (detail.addToComposite) ? 'https://' + image.imageURL : '';
									this.hasElectronicsImage = (detail.addToComposite) ? true : false;
								}
							}else {
								this.motorImage = 'https://' + image.imageURL;
       				}
						}
					}

					if(this.page === 'summary'){
						if(image.imageType === 'frontAngle'){
							this.motorImage = 'https://' + image.imageURL;
						}
					}
				}
			}else{
				console.log('no back left, show default');
				if(detail.optionName === 'Black Powder Coated Trailer'){
					console.log('default image', this.defaultImage);
					this.boatImage = 'https://' + this.defaultImage;
				}
			}
		}
}