/**
 * Created by Legend on 28/10/21.
 */

import { LightningElement, api, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import fetchERPOrderItems from '@salesforce/apex/ERPPricingUpdate.fetchERPItems';
import updateMaterials from '@salesforce/apex/ERPPricingUpdate.updateMaterialRecords';
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
    wiredItems(result){
        if(result.data){
            console.log('result');
            console.log(result);
            //console.log( JSON.parse( JSON.stringify( result.data ) ) );
            this.materialList = JSON.parse(result.data);
            this._dataLoaded = true;
            this.ready = true;
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
                return refreshApex(this.materialList);
            })
            .catch(error=>{
                alert('Problem in updating records: '+JSON.stringify(error));
                this._spinner.close();
            })
        }
    }

    getERPItems()
    {
      return fetchERPOrderItems( { erpId: this.recordId} );
    }
}