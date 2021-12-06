/**
 * Created by Legend on 28/10/21.
 */

import { LightningElement, api, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import fetchERPOrderItems from '@salesforce/apex/ERPPricingUpdate.fetchERPItems';
import updateMaterials from '@salesforce/apex/ERPPricingUpdate.updateMaterialRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { errorToast, reduceErrors } from 'c/utils';
const COLS=[
   {label:'Product',fieldName:'productName', type:'text'},
   {label:'Current Price',fieldName:'currentUnitPrice', type:'currency'},
   {label:'Pricebook Price',fieldName:'priceBookUnitPrice', type:'currency'},
   {label:'Price Changed',fieldName:'isDifferent', type:'boolean'}
 ];
export default class ERPPricingUpdate extends LightningElement {
    cols=COLS;
    @api recordId;
    @api materialIds;
    @api materialList;
    ready=false;
    error;
    _spinner;
    _rendered = false;
    _dataLoaded = false;

    renderedCallback()
    {
        if( !this._rendered )
        {
          this._spinner = this.template.querySelector('c-legend-spinner');
          this._spinner.open();
          this._rendered = true;
        }
        this.init();
    }

    @wire(fetchERPOrderItems, { erpId: '$recordId'})
    wiredItems({error, data}){
        if(data){
            console.log('result');
//            console.log(data);
            this.materialList = JSON.parse(data);
            this._dataLoaded = true;
            this.ready = true;
        }else if(error){
            console.log('error');
//            console.log(error);
            this.error = error.body.message;
            this._spinner.close();
        }
    }

    init()
    {
      if( this._rendered && this._dataLoaded )
      {
        this._spinner.close();
      }
    }

    updateRecords(){
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        console.log('selectedRecords');
        console.log(selectedRecords);
        var matlIds = [];
        for(var i=0; i<selectedRecords.length; i++){
            matlIds.push(selectedRecords[i].idMaterial);
        }
        console.log('matlIds'); 
        console.log(matlIds);
        if(matlIds.length > 0){
            this._spinner.open();
            updateMaterials({setIdMaterials: matlIds,erpId: this.recordId})
            .then(result=>{
                console.log('result 2');
                console.log(result.data);
                this.materialList = JSON.parse(result);
                this._spinner.close();
                this.showToast('Success','Update successful. Please refresh this page to reload records.','success');
                return refreshApex(this.materialList);
            })
            .catch(error=>{
                console.log('error');
                console.log(error);
                this.showToast('Error',JSON.stringify(error),'error');
                this._spinner.close();
            })
        }
    }

    getERPItems()
    {
      return fetchERPOrderItems( { erpId: this.recordId} );
    }

    showToast(tTitle,tMessage,tVariant) {
        const event = new ShowToastEvent({
            title: tTitle,
            message: tMessage,
            variant: tVariant
        });
        this.dispatchEvent(event);
    }
}