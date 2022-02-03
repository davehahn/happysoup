/**
 * Created by Tim on 2021-07-09.
 */

import { LightningElement, api, wire } from 'lwc';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName, formatPrice, weeklyPayment, renderEN, renderFR } from 'c/communitySharedUtils';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import fetchNewInStockInventory from '@salesforce/apex/FactoryStore_InventoryController.fetchNewInStockInventory';
import fetchFullBoatDetails from '@salesforce/apex/FactoryStore_InventoryController.fetchFullBoatDetails';

export default class FactoryStoreCurrentInventoryList extends NavigationMixin(LightningElement) {

	@api boat;
	@api boatId;
	@api locationName;

	startingRetailPrice;
	startingWeeklyPrice;
	boatName;
	modelListingPhoto;
	standardMotor;
	standardTrailer;
	standardTollingMotor;
	overallLength;
	centerlineLength;
	packageLength;

	storeStock = [];
	currentStock = [];
	hasCurrentStock = false;
	currentStockQuantity;
	nonCurrentStock = [];
	hasNonCurrentStock = false;
	nonCurrentStockQuantity;

	parseCurrentStock = [];
	parseNonCurrentStock = [];

	stockPromises = [];

	pBoat;
	pBoatName;
	pStock = [];

	isEN = renderEN();
	isFR = renderFR();

	calendarYear = new Date().getFullYear();
	calendarMonth = new Date().getMonth();
	modelYear;

	lookupHasRunPreviously = false;

	@wire(CurrentPageReference) pageRef;

	connectedCallback(){
	  this.startingRetailPrice = (this.isEN) ? formatPrice(this.boat.Expanded.RetailPrice, true) : formatPrice(this.boat.Expanded.RetailPrice, true, 'fr');
		this.startingWeeklyPrice = (this.isEN) ? weeklyPayment(this.boat.Expanded.RetailPrice) : weeklyPayment(this.boat.Expanded.RetailPrice, 'fr');
		this.boatName = this.setBoatName(stripParentheses(this.boat.Base.Name));
		this.modelListingPhoto = 'background-image: url(' + this.boat.Base.Default_Gallery_Image_Original__c + ')';
		this.standardMotor = (this.boat.Base.Standard_Motor__r) ? rewriteMotorName(this.boat.Base.Standard_Motor__r.Name) : '';
		if(this.isEN){
			this.standardTrailer = (this.boat.Base.Standard_Trailer__r) ? ' and ' + rewriteTrailerName(this.boat.Base.Standard_Trailer__r.Name) : '';
		} else {
			this.standardTrailer = (this.boat.Base.Standard_Trailer__r) ? ' et ' + rewriteTrailerName(this.boat.Base.Standard_Trailer__r.Name) : '';
		}
		if (this.boat.Base.Overall_Length__c) {
			this.overallLength = convertLength(this.boat.Base.Overall_Length__c);
		}
		if (this.boat.Base.Length__c) {
			this.centerlineLength = convertLength(this.boat.Base.Length__c);
		}
		if (this.boat.Base.Package_Length__c) {
			this.packageLength = convertLength(this.boat.Base.Package_Length__c);
		}



		if(this.lookupHasRunPreviously){
		  console.log('clear stock array');
		  if(this.currentStock.length > 0){
		    this.currentStock.length = 0;
		    this.parseCurrentStock.length = 0;
		    this.parseNonCurrentStock.length = 0;
    	}
		}

	  this.pBoat = JSON.parse(JSON.stringify(this.boat));
	  this.pBoatName = stripParentheses(this.pBoat.Base.Name);
	  console.log('run lookup for ' + this.pBoat.Base.Name);

	  this.modelYear = (this.calendarMonth >= 9) ? this.calendarYear + 1 : this.calendarYear;
	  console.log('current model year: ', this.modelYear);


		const inventory = fetchNewInStockInventory({ location: parseLocationName(this.locationName), year: this.modelYear, modelId: this.boatId })
			.then((boats) => {
			  this.lookupHasRunPreviously = true;
			  if(boats.RiggedBoats.length > 0){
			    boats.RiggedBoats.forEach((boat, index) => {
						let setSavings = (typeof boat.Serial.serialSavings === 'undefined') ? 0 : boat.Serial.serialSavings;
						this.storeStock.push({
							Base: {
								SerialId: boat.Serial.serialNumberId,
								ProductName: stripParentheses(boat.Serial.productName),
								ProductId: boat.Serial.productId,
								SerialNumber: boat.Serial.serialNumberValue,
								SerialModelYear: boat.Serial.serialModelYear,
								BaseRetailPrice: this.pBoat.Expanded.RetailPrice,
								StartingWeeklyPrice: weeklyPayment(this.pBoat.Expanded.RetailPrice),
								StartingRetailPrice: this.pBoat.Expanded.RetailPrice,
								SpecialRetailPrice: 0,
								SpecialWeeklyPrice: 0,
								HasSpecialPrice: false,
								Savings: setSavings,
								ActualRetailPrice: 'TBD',
								ActualWeeklyPrice: 'TBD',
								Equipment: []
							},
							Expanded: this.pBoat
						});
						if(boat.Equipment){
//						  console.log('%chas equipment, figure out price', 'font-size:2rem;color:lightblue;');
						 let retailUpgradeCost = 0;
						 boat.Equipment.forEach((e, i) => {
								if(e.productType === 'Motor'){
//								  console.log('%cthis is the motor upgrade, figure out price', 'font-size:2rem;color:lightblue;');
									// TO FIX!! fullBoat is not the full boat details. need to figure this out for upgrade stuff to work!
									if(typeof this.pBoat.Expanded.MotorUpgrades !== 'undefined'){
										this.pBoat.Expanded.MotorUpgrades.forEach( (motor, index) => {
											if(motor.Id === e.productId){
											  // TODO - check to see if retail upgrade cost !== undefined, else set to 0.
//												console.log('motor.RetailUpgradeCost boat ' + index + ': ', motor.RetailUpgradeCost);
//												retailUpgradeCost += motor.RetailUpgradeCost;
												let upgradeCost = motor.RetailUpgradeCost;
												console.log('motor.RetailUpgradeCost boat ' + index + ': ', upgradeCost);
												if(upgradeCost === void 0){
//													console.log('%cmotor upgrade cost is undefined, set to 0', 'font-size:2rem;color:lightblue;');
													retailUpgradeCost += 0;
												} else{
//													console.log('%cmotor upgrade cost is defined, use it', 'font-size:2rem;color:lightblue;');
													retailUpgradeCost += upgradeCost;
												}
											}
										});
									}
								} else {
									if(typeof this.pBoat.Expanded.TrailerUpgrades !== 'undefined'){
//									  console.log('%cthis is the trailer upgrade, figure out price', 'font-size:2rem;color:lightblue;');
										this.pBoat.Expanded.TrailerUpgrades.forEach( (trailer, index) => {
											if(trailer.Id === e.productId){
											  // TODO - check to see if retail upgrade cost !== undefined, else set to 0.
//												console.log('trailer.RetailUpgradeCost boat ' + index + ': ', trailer.RetailUpgradeCost);
//												retailUpgradeCost += trailer.RetailUpgradeCost;
												let upgradeCost = trailer.RetailUpgradeCost;
												console.log('trailer.RetailUpgradeCost boat ' + index + ': ', upgradeCost);
												if(upgradeCost === void 0){
//												  console.log('%ctrailer upgrade cost is undefined, set to 0', 'font-size:2rem;color:lightblue;');
													retailUpgradeCost += 0;
												} else{
//												  console.log('%ctrailer upgrade cost is defined, use it', 'font-size:2rem;color:lightblue;');
													retailUpgradeCost += upgradeCost;
												}
											}
										});
									}
								}

								let productName = (e.productType === 'Motor') ? rewriteMotorName(e.productName) : rewriteTrailerName(e.productName);
								this.storeStock[index].Base.Equipment.push({
									ProductType: e.productType,
									ProductId: e.productId,
									ProductName: productName
								});
								this.storeStock[index].Base.Equipment.sort(function(a, b) {
									 return a.ProductType.toLowerCase().localeCompare(b.ProductType.toLowerCase());
								});

							});

							console.log('full upgrade cost boat ' + index + ':', retailUpgradeCost);

							this.storeStock[index].Base.RetailUpgradeCost = retailUpgradeCost;
							this.storeStock[index].Base.StartingRetailPrice = this.pBoat.Expanded.RetailPrice + retailUpgradeCost;

							this.storeStock[index].Base.HasSpecialPrice = (this.storeStock[index].Base.Savings < 0) ? true : false;
							this.storeStock[index].Base.SpecialRetailPrice = (this.pBoat.Expanded.RetailPrice + this.storeStock[index].Base.Savings) + retailUpgradeCost;

							if(this.storeStock[index].Base.SerialModelYear === this.modelYear){
								 this.parseCurrentStock.push(this.storeStock[index]);
       				} else {
       					this.parseNonCurrentStock.push(this.storeStock[index]);
           		}
						} else {
//						  console.log('%cno equipment, show standard retail price', 'color:green;font-size:1rem');
						  this.storeStock[index].Base.RetailUpgradeCost = 0;
							this.storeStock[index].Base.StartingRetailPrice = this.pBoat.Expanded.RetailPrice;

							this.storeStock[index].Base.HasSpecialPrice = (this.storeStock[index].Base.Savings < 0) ? true : false;
							this.storeStock[index].Base.SpecialRetailPrice = (this.pBoat.Expanded.RetailPrice + this.storeStock[index].Base.Savings);

							if(this.storeStock[index].Base.SerialModelYear === this.modelYear){
								 this.parseCurrentStock.push(this.storeStock[index]);
							} else {
								this.parseNonCurrentStock.push(this.storeStock[index]);
							}
      			}
					});
					this.triggerStockList();
     		} //if(boats.length > 0){
			}).catch(e => {
				console.log('Fetch Inventory Error: ', e);
			});
 	}

 	renderedCallback(){
  	  this.initTabs('details');
	}

 	triggerStockList(){
//		console.log('current ' + boatName + ' inventory (component): ', this.storeStock);

		console.log('current year stock: ', this.parseCurrentStock);
		console.log('non current year stock: ', this.parseNonCurrentStock);

		this.formatListingPrices(this.parseCurrentStock);
		this.formatListingPrices(this.parseNonCurrentStock);

		this.currentStock = this.parseCurrentStock;
		this.nonCurrentStock = this.parseNonCurrentStock;

		this.hasCurrentStock = (this.currentStock.length > 0) ? true : false;
		this.currentStockQuantity = this.currentStock.length;
		this.hasNonCurrentStock = (this.nonCurrentStock.length > 0) ? true : false;
		this.nonCurrentStockQuantity = this.nonCurrentStock.length;
//		this.storeStockQuantity = this.currentStock.length + this.nonCurrentStock.length;

		const passStockEvent = new CustomEvent('updatestockvalue', {
			detail: this.storeStockQuantity
  	});
  	this.dispatchEvent(passStockEvent);

	}

	formatListingPrices(list){
	  list.forEach((boat, index) => {
			boat.Base.StartingWeeklyPrice = (this.isEN) ? weeklyPayment(boat.Base.StartingRetailPrice) : weeklyPayment(boat.Base.StartingRetailPrice, 'fr');
			boat.Base.StartingRetailPrice = (this.isEN) ? formatPrice(boat.Base.StartingRetailPrice, true) : formatPrice(boat.Base.StartingRetailPrice, true, 'fr');

			boat.Base.SpecialWeeklyPrice = (this.isEN) ? weeklyPayment(boat.Base.SpecialRetailPrice) : weeklyPayment(boat.Base.SpecialRetailPrice, 'fr')
			boat.Base.SpecialRetailPrice = (this.isEN) ? formatPrice(boat.Base.SpecialRetailPrice, true) : formatPrice(boat.Base.SpecialRetailPrice, true, 'fr');
		});
		return list;
 	}

	navigateToCommunityPage(pageName, params) {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				pageName: pageName
			},
			state: params
		});
	}

	setBoatName(name){
		return (this.isFR) ? 'Serie ' + name.replace('-Series', '') : name;
	}

	initTabs(target){
		let tabs = this.template.querySelectorAll('.nav__item');
		let sections = this.template.querySelectorAll('.outline__section');
		tabs.forEach((tab, index) => {
		  let thisTarget = tab.dataset.target;
			if(target === thisTarget){
				tab.classList.add('active');
   		} else{
   			tab.classList.remove('active');
     	}
  	});
  	sections.forEach((section, index) => {
  	  let thisTarget = section.dataset.target;
			if(target === thisTarget){
				section.classList.add('active');
				section.classList.remove('inactive');
			} else {
			  section.classList.remove('active');
				section.classList.add('inactive');
   		}
		});
 	}

	changeTab(event){
	  console.log('change tab!');
	  console.log(event.currentTarget.dataset.target);
	  this.initTabs(event.currentTarget.dataset.target);
 	}

	navToBoat(event) {
		let page = 'boat-model',
			params = {
				c__recordId: event.currentTarget.dataset.record
			};
		this.navigateToCommunityPage(page, params);
		event.preventDefault();
	}

	get boatSpecs(){
      let props = JSON.parse(stringy(this.boat.Expanded.BoatSpecs));
      let translate = {
      		'Package Width' : { 'fr' : 'Largeur de l’ensemble', 'unit' : '&rdquo;'},
      		'Package Length': {'fr' : 'Longueur de l’ensemble', 'unit' : 'convertLength'},
      		'Bottom Width' : {'fr' : 'Largeur du fond', 'unit' : '&rdquo;'},
      		'Inside Depth' : {'fr' : 'Profondeur intérieure', 'unit' : '&rdquo;'},
      		'Hull Depth' : {'fr' : 'Profondeur max.', 'unit' : '&rdquo;'},
      		'Aluminum Thickness' : {'fr' : 'Épaisseur d’aluminium', 'unit' : ''},
      		'Color' : {'fr' : 'Couleur', 'unit' : '', 'translations' : {'Black' : 'Noir', 'Black / Charcoal' : 'Noir / Charbon', 'White / Black' : 'Blanc / Noir', 'Dark Blue/White' : 'Bleu Foncé/Blanc'}},
      		'Cup Holders' : {'fr' : 'Portes-gobelets', 'unit' : ''},
      		'Maximum Horsepower' : {'fr' : 'Puissance max.', 'unit' : ''},
      		'Maximum Capacity' : {'fr' : 'Charge max.', 'unit' : ' lbs'},
      		'Beam' : {'fr' : 'Largeur', 'unit' : '&rdquo;'},
      		'Centerline Length' : {'fr' : 'Longueur du centre', 'unit' : 'convertLength'},
      		'Length' : {'fr' : 'Longueur du centre', 'unit' : 'convertLength'},
      		'Towing Weight' : {'fr' : 'Poids de remorquage', 'unit' : ' lbs'},
      		'Fuel Capacity' : {'fr' : 'Réservoir d’essence', 'unit' : ''},
      		'Pontoon Aluminum Thickness' : {'fr' : 'Épaisseur des tubes', 'unit' : ''},
      		'Pontoon Diameter' : {'fr' : 'Diamètre des tubes', 'unit' : '&rdquo;'},
      		'Overall Length' : {'fr' : 'Longueur', 'unit' : 'convertLength'},
      		'Maximum Persons' : {'fr' : 'Capacité-personnes', 'unit' : ''},
      		'Pontoon Length' : {'fr' : 'Longueur des tubes', 'unit' : 'convertLength'},
      		'Deck Length' : {'fr' : 'Longueur de pont', 'unit' : 'convertLength'},
      		'Livewell / Cooler' : {'fr' : 'Vivier/ Glacière', 'unit' : ''},
      		'Weight' : {'fr' : 'Poids', 'unit' : ' lbs'}
      	};

      	let sortOrder;
      	let sortedArray = [];

      	if(this.boat.Expanded.Family === 'Pontoon'){
      	  console.log("it's a pontoon");
      		sortOrder = ['Overall Length', 'Beam', 'Maximum Horsepower', 'Fuel Capacity', 'Deck Length', 'Pontoon Length', 'Pontoon Diameter', 'Maximum Persons', 'Maximum Capacity', 'Weight'];
      	} else if(this.boat.Expanded.Family === 'Deck Boat'){
      	  console.log("it's a deck boat");
      		sortOrder = ['Overall Length', 'Beam', 'Inside Depth', 'Maximum Horsepower', 'Fuel Capacity', 'Hull Depth', 'Package Length', 'Maximum Persons', 'Towing Weight', 'Maximum Capacity'];
      	} else {
      	  console.log("it's a fishing boat");
      	  sortOrder = ['Centerline Length', 'Beam', 'Hull Depth', 'Inside Depth', 'Aluminum Thickness', 'Maximum Horsepower', 'Maximum Capacity', 'Weight', 'Bottom Width', 'Package Length', 'Package Width', 'Towing Weight', 'Livewell / Cooler', 'Fuel Capacity'];
       }
  			console.log('sortOrder', sortOrder);
  			console.log('props', props);

  			sortOrder.forEach((sOption, sIndex) => {
  				for (const [pIndex, pOption] of Object.entries(props)) {
  				  if(sOption === pIndex){
  				    let spec = pOption + translate[pIndex].unit;
  						let unit = translate[pIndex].unit;
  				    if(translate[pIndex].unit === 'convertLength'){
  							let truncateLengthTrailingZero = true;
  							if((this.recordId === '01t1Y00000ATJfUQAX') && (pIndex === 'Overall Length')){
  								truncateLengthTrailingZero = false;
  							} else if((this.recordId === '01ti0000004zco9AAA') && (pIndex === 'Length')){
  								truncateLengthTrailingZero = false;
  							} else if((this.recordId === '01t1Y00000ATDipQAH') && (pIndex === 'Centerline Length' || pIndex === 'Deck Length')){
  								truncateLengthTrailingZero = false;
  							}
  							spec = convertLength(pOption, truncateLengthTrailingZero);
          		}

  						let specName = (this.isEN) ? pIndex : translate[pIndex].fr;
  				  	sortedArray[sIndex] = {
  				  	 'Name': specName,
  				  	 'Value': '<strong>' + spec + '</strong>'
         			};
        		}
      		}
     		});
  			let filteredArray = sortedArray.filter((el) => {
  				return el != null;
     		});
     		console.log('filteredArray', filteredArray);
     		return filteredArray;
    }

}