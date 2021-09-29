/**
 * Created by Tim on 2021-05-07.
 */

import { LightningElement, api, wire } from 'lwc';
import fetchStaffList from '@salesforce/apex/FactoryStoreStaffList_Controller.fetchStaffList';
import { setWrapperClass, renderEN, renderFR } from 'c/communitySharedUtils';
import Id from '@salesforce/community/Id';
import fetchCommunityDetails from '@salesforce/apex/CommSharedURL_Controller.fetchCommunityDetails';
import { stringy, stripParentheses, rewriteMotorName, rewriteTrailerName, convertLength, parseLocationName } from 'c/communitySharedUtils';

export default class FactoryStoreStaffList extends LightningElement {
	@api locationName;
	@api department;
	@api sectionWidth;

	users;
	showUserListing = false;
	showLoading = true;
	profilePhotoUrl;
	communityUrl;
	wrapperClass = 'staff';

	isEN = renderEN();
	isFR = renderFR();

	@wire( fetchCommunityDetails, {communityId: Id} )
		wiredFetchCommunityDetails( { error, data } )
		{
			if( data )
			{
				this.locationName = data.name;
				this.communityUrl = data.siteUrl;
				this.runFetchStaffList();
			}
			else if( error )
			{
				console.log('fetch community error: ', error);
			}
		}

	runFetchStaffList(){
	  if(this.locationName){
	    fetchStaffList({location: parseLocationName(this.locationName), department: this.department})
				.then( (result) => {
					this.showUserListing = true;
					this.showLoading = false;
					this.wrapperClass = setWrapperClass(this.sectionWidth, 'staff');
						let trunkCommUrl = this.communityUrl.slice(0, (this.communityUrl.indexOf('.com') + 4));
						let newData = result.map((item) => ({
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
					console.log('fetch places api error: ', e);
			 });
   }
 }
}