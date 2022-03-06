/**
 * Created by aminrubel on 13/2/20.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveSerialNumbersFromPO from '@salesforce/apex/gcLegendMRP.retrieveUnimprovedHulls_LWC';
import saveWOFromSerial from '@salesforce/apex/purchaseOrder_CreateWorkOrder.createWOFromSerial';
const columns = [
    { label: 'Name', fieldName: 'serialName' },
    { label: 'Lot', fieldName: 'lotName' },
    { label: 'Product', fieldName: 'productName' }
];

export default class purchaseOrder_CreateWorkOrder extends LightningElement {
    @api recordId;
    @track poSerialNumbers = [];
    @track columns = columns;
    @track loaded = false;

//    async connectedCallback() {
//        const data = await retrieveSerialNumbersFromPO({ idPurchaseOrder: '$recordId' });
//        this.poSerialNumbers = data;
//    }
//    @wire(retrieveSerialNumbersFromPO,{idPurchaseOrder:'$recordId'}) poSerialNumbers;
//    @track poSerialNumbers;
    connectedCallback(){
        this.retrieveRecords();
    }

    retrieveRecords(){
        retrieveSerialNumbersFromPO({
            idPurchaseOrder:this.recordId,
            timeString: Math.random()
        })
        .then(result=>{
            console.log(result);
            this.poSerialNumbers = result;
        })
        .catch(error => {
            console.log('error'+error.message);
        });

    }

    handleClick(){
        var el = this.template.querySelector('lightning-datatable');
        var selected = el.getSelectedRows();
        console.log(selected);
        if(selected.length == 0){
            this.showToast('Failed', 'Please select serial numbers to create Work orders.', 'error');
            return;
        }
        this.toggleSpinner();
        console.log(selected);
        saveWOFromSerial({
            idPurchaseOrder:this.recordId,
            listSerial: JSON.stringify(selected)
        })
        .then(result=>{
            this.showToast('Work Order Creation', 'Work Orders were Created Successfully!', 'success');
            console.log(result);
            this.retrieveRecords();
            this.toggleSpinner();
            this.showSuccess();
        })
        .catch(error => {
            console.log(error);
            console.log('error'+error.body.message);
            this.showToast('Failed', error.body.message, 'error');
            this.toggleSpinner();
        });
    }

    showSuccess() {
        const filters = {'closeThis' : 'true'};
        const filterChangeEvent = new CustomEvent('successcreate', {
            detail: { filters },
        });
        // Fire the custom event
        console.log('Here fire');
        this.dispatchEvent(filterChangeEvent);
    }

    showToast(tle, msg, vari) {
        const evt = new ShowToastEvent({
            title: tle,
            message: msg,
            variant: vari,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    toggleSpinner() {
        this.loaded = !this.loaded;
    }
}