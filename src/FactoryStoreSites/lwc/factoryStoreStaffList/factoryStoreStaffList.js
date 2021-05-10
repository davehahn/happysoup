/**
 * Created by Tim on 2021-05-07.
 */

import { LightningElement, api, wire } from 'lwc';
import fetchStaffList from '@salesforce/apex/FactoryStoreStaffList_Controller.fetchStaffList';

export default class FactoryStoreStaffList extends LightningElement {
	@api location;
	@api department;
	users;
	showUserListing = false;
	profilePhotoUrl;

	@wire( fetchStaffList, { location: '$location'} )
		wiredFetchStaffList( {error, data})
		{
			if( data )
			{
				console.log('user Data: ', data);
				this.users = data;
				this.showUserListing = true;
   		}
   		else if( error )
   		{
   			console.log('fetch user error: ', error);
    	}
  	}
}