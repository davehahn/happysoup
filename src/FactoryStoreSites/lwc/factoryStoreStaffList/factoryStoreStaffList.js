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

	@wire( fetchStaffList, { location: '$location', department: '$department'} )
		wiredFetchStaffList( {error, data})
		{
			if( data )
			{

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
								EmailTrunk: item.Email.replace('.invalid', ''),
								EmailLink: 'mailTo:' + item.Email.replace('.invalid', ''),
								PhoneLink: 'tel:' + item.Phone,
								Hometown: 'Mississauga',
								StartYear: '2019',
								Story: 'Quisque dapibus Leo ut mauris ultricies consectetur sit amet non leo. Pellentesque quis velit elit. Donec consectetur sem vitae lorem ultrices, eu fermentum augue fermentum. Duis non porttitor metus. Cras vel velit enim. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.',
								LandscapeImg: 'background-image: url("https://mk0inventorylegv1t7j.kinstacdn.com/wp-content/uploads/2020/05/LegendLandscape-12.jpg")'
							}));
							this.users = newData;
							console.log('user newData: ', newData);
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