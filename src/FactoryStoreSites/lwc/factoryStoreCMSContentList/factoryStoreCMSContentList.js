/**
 * Created by Tim on 2021-04-26.
 */

import { LightningElement, wire, api, track } from 'lwc';

import initMethod from '@salesforce/apex/FactoryStore_MCWrapperController.initMethod';

export default class FactoryStoreCmsContentList extends LightningElement {
	@api contentType = 'Legend_Deals';
	@track content;

  @wire( initMethod, { contentType: '$contentType' } )
  	wiredInitMethod( { error, data })
  	{
  	 	if( data )
  	  {
  	    console.log('get ' + this.contentType, data);
  	    this.content = data;
     	}
     	else if ( error )
     	{
      	console.log('fetch content error:', error);
     	}
   }

}