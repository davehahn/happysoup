/**
 * Created by dave on 2020-04-09.
 */

import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LOGO from '@salesforce/resourceUrl/LegendLogo';

export default class CustCommPublicMain extends NavigationMixin(LightningElement) {

  logo = LOGO;
  pageMap = [
    {
      pageName: 'boat1page',
      recordId: 'recordIdOne'
    },
    {
      pageName: 'boat2page',
      recordId: 'recordIdTwo'
    },
    {
      pageName: 'boat3page',
      recordId: 'recordIdThree'
    }
  ]

  toggleMenu()
  {
    this.template.querySelector('.overlay').classList.toggle('open');
    this.template.querySelector('.slide-menu').classList.toggle('open');
  }

  navToBoat( event )
  {
    event.preventDefault();
    let page = this.pageMap[event.target.dataset.menuNumber],
        params = {
          c__recordId: page.recordId
        };

    this.navigateToCommunityPage( page.pageName, params );
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
