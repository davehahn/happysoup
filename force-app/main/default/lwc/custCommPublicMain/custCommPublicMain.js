/**
 * Created by dave on 2020-04-09.
 */

import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LOGO from '@salesforce/resourceUrl/LegendLogo';
import fetchBoats from '@salesforce/apex/OnlineBoatReservation_Controller.fetchBoats';

export default class CustCommPublicMain extends NavigationMixin(LightningElement) {

  logo = LOGO;
  @wire( fetchBoats ) boats;
  boatMap = [
    {
      name: 'Boat 1',
      recordId: 'recordIdOne'
    },
    {
      name: 'Boat 2',
      recordId: 'recordIdTwo'
    },
    {
      name: 'Boat 3',
      recordId: 'recordIdThree'
    }
  ];

  toggleMenu()
  {
    this.template.querySelector('.overlay').classList.toggle('open');
    this.template.querySelector('.slide-menu').classList.toggle('open');
  }

  navToBoat( event )
  {
    event.preventDefault();

    let page = 'order-builder',
        params = {
          c__recordId: event.target.dataset.recordId
        };

    this.navigateToCommunityPage( page, params );
  }

  handleSignIn( event )
  {
    //this.navigateToCommunityPage( 'my-home', {} );
    this[NavigationMixin.Navigate]({
      type: 'comm__loginPage',
         attributes: {
             actionName: 'login'
         }
    });
  }

  navigateToCommunityPage( pageName, params )
  {
    console.log( pageName );
    console.log( params );
    this[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
            pageName: pageName
        },
        state: params
    });
  }

}
