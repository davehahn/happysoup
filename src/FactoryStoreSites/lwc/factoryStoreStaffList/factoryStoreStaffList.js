/**
 * Created by Tim on 2021-05-07.
 */

import { LightningElement, api, wire } from 'lwc';
import fetchStaffList from '@salesforce/apex/FactoryStoreStaffList_Controller.fetchStaffList';
import { setWrapperClass } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';
import fetchCommunityUrl from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityUrl';

export default class FactoryStoreStaffList extends LightningElement {
	@api location;
	@api department;
	@api sectionWidth;

	users;
	showUserListing = false;
	showLoading = true;
	profilePhotoUrl;
	communityUrl;
	wrapperClass = 'staff';

	@wire( fetchStaffList, { location: '$location'} )
		wiredFetchStaffList( {error, data})
		{
			if( data )
			{
				console.log('user Data: ', data);
				this.showUserListing = true;
				this.showLoading = false;
				this.wrapperClass = setWrapperClass(this.sectionWidth, 'staff');
				fetchCommunityUrl({communityId: Id})
					.then( (result) => {
						console.log('fetch community url result: ', result);
							this.communityUrl = result;
							let trunkCommUrl = result.slice(0, (result.indexOf('.com') + 4));
							let newData = data.map((item) => ({
								...item,
								ProfileImgUrl: trunkCommUrl + item.MediumPhotoUrl,
								EmailLink: 'mailTo:' + item.Email,
								PhoneLink: 'tel:' + item.Phone
							}));
							this.users = newData;
					 }).catch(e => {
						 console.log('fetch community url error: ', e);
					 });
   		}
   		else if( error )
   		{
   			console.log('fetch user error: ', error);
    	}
  	}
}