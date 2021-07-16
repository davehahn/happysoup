/**
 * Created by dave on 2021-07-13.
 */

import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import  getIssueTypes from '@salesforce/apex/IssueLauncher_Controller.fetchIssueTypes';

export default class IssueLauncher extends NavigationMixin(LightningElement) {

  menuItems;

  @wire( getIssueTypes )
  wiredIssueTypes( { error, data } )
  {
   if( data )
   {
     console.log( JSON.parse( JSON.stringify(data)) );
     this.menuItems = data;
   }
   else if( error )
   {
     console.log( error );
   }
  }

  openNew( objectApiName )
  {
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
          objectApiName: objectApiName,
          actionName: 'new'
      }
    });
  }

  handleIssue( event )
  {
    this.fireSelectedEvent();
    this.openNew(
      event.currentTarget.dataset.sobjectName
    );
  }

  fireSelectedEvent()
  {
    const evt = new CustomEvent('selected');
    this.dispatchEvent( evt );
  }
}