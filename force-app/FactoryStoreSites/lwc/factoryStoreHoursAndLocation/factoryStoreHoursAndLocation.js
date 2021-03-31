/**
 * Created by Tim on 2021-03-30.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';


export default class FactoryStoreHoursAndLocation extends LightningElement {

	@api storeLocation;
}