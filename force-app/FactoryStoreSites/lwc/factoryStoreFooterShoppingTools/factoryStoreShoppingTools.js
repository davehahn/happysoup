/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from 'lwc';

export default class FactoryStoreShoppingTools extends LightningElement {
	@api toolsFindADealer;
	@api toolsShowroomVisit;
	@api toolsRequestAQuote;
	@api toolsBuildPrice;
	@api toolsDownloadCatalogue;
}