/**
 * Created by dave on 2020-02-24.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

export default class CommissionRecordHeader extends LightningElement {

  @api commissionRecords;
  @track selectedRecord;
  @track menuItems;
  @track isEditingPayment=false;
  @wire(CurrentPageReference) pageRef;

  connectedCallback()
  {
    this.selectedRecord = this.commissionRecords[0];
    console.log( JSON.parse( JSON.stringify( this.selectedRecord ) ) );
    this.dispatchChangeEvent();
    this.menuItems = Array.from( this.commissionRecords, record =>
      new Object( {
        id: record.id,
        name: record.taskName,
        selected: record.id === this.selectedRecord.id
      })
    );
    registerListener('paymentEditComplete', this.handlePaymentEditComplete, this );
    registerListener('paymentsValidation', this.handlePaymentsValidation, this );
  }

  disconnectedCallback()
  {
    unregisterAllListeners( this );
  }

  get title()
  {
    let title = 'Commission Record';
    if( this.commissionRecords.length > 0 )
    {
      title += 's';
    }
    return title;
  }

  get menuDisabled()
  {
    return this.isEditingPayment === true;
  }

  get selectedTaskURL()
  {
    return `/${this.selectedRecord.taskId}`;
  }

  handleMenuSelect(event)
  {
    this.selectedRecord = this.commissionRecords.find( cr => cr.id === event.detail.value );
    this.menuItems.map( item => item.selected = item.id === this.selectedRecord.id );
    this.dispatchChangeEvent();
  }

  dispatchChangeEvent()
  {
    const record = this.selectedRecord;
    const changeEvt = new CustomEvent( 'recordchange', {
      detail: { record }
    });
    this.dispatchEvent( changeEvt );
  }
}