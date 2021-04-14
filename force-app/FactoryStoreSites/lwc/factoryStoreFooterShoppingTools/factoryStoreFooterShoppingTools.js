/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import FactoryStoreGlobals from '@salesforce/resourceUrl/FactoryStoreGlobals';

export default class FactoryStoreShoppingTools extends LightningElement {

	@api toolsFindADealer;
	@api toolsShowroomVisit;
	@api toolsRequestAQuote;
	@api toolsBuildPrice;
	@api toolsDownloadCatalogue;

	calendarIcon = `${FactoryStoreGlobals + '/img/calendar.svg'}#calendarIcon`;
	contractIcon = `${FactoryStoreGlobals + '/img/contract.svg'}#contractIcon`;
	downloadIcon = `${FactoryStoreGlobals + '/img/download.svg'}#downloadIcon`;
	pinIcon = `${FactoryStoreGlobals + '/img/pin.svg'}#pinIcon`;
}