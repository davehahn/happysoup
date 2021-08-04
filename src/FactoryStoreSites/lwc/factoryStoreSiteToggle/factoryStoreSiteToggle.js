/**
 * Created by Tim on 2021-05-31.
 */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

export default class FactoryStoreSiteToggle extends NavigationMixin(LightningElement) {

	@wire(CurrentPageReference) pageRef;

	get siteList() {
      return [
        { label: 'LegendBoats.com', value: 'https://www.legendboats.com' },
        { label: 'Legend Boats Barrie', value: 'https://barrie.legendboats.com' },
        { label: 'Legend Boats Ste-Marthe-Sur-Le-Lac', value: 'https://montreal.legendboats.com' },
        { label: 'Legend Boats Sudbury', value: 'https://sudbury.legendboats.com' },
      ];
    }

  navigateToSite( e ){
    e.preventDefault();

    console.log('value', e.currentTarget.value);
    window.open(e.currentTarget.value);
  }

}