/**
 * Created by dave on 2021-03-29.
 */

import { LightningElement, api, wire, track } from 'lwc';
import fetchMaterials from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.fetchMaterials';
import createRecords from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.createBackOrderERP';

export default class ErpCreatePartsBackorder extends LightningElement {

  @api recordId;
  @api currentStep;

  @track materials=[];
  @track taskCause;

  transferredMaterials=[];
  retailERP;
  newERP={};
  newTask={};
  newMaterials=[];

  _creditProductId;
  _erpCopyFields = [
    'AcctSeed__Account__c',
    'GMBLASERP_Warehouse__c',
    'GL_Account_Variable_1__c',
    'GL_Account_Variable_2__c',
    'GL_Account_Variable_3__c'
  ];

  @wire( fetchMaterials, { recordId: '$recordId' } )
  wiredFetchMaterials( result )
  {
    if( result.data )
    {
      console.log( JSON.parse(JSON.stringify(result.data)));
      let resultMaterials = JSON.parse(JSON.stringify( result.data.materials ) );
      resultMaterials.reduce( (materials, mat ) => {
        mat.quantityTransferred = mat.AcctSeedERP__Quantity_Per_Unit__c - mat.AcctSeedERP__Quantity_Allocated__c;
        materials.push( mat );
        return materials;
      }, this.materials );

      this.retailERP = result.data.retailERP;
      console.log( JSON.parse(JSON.stringify(this.materials)));

      this._creditProductId = result.data.creditProductId;
      this.isBusy = false;
    }
    if( result.error )
    {
      console.log( result.error );
    }
  }

  @api stepOne()
  {
    this.transferredMaterials = this.materials.filter( mat => mat.quantityTransferred > 0 );
    console.log( JSON.parse( JSON.stringify( this.transferredMaterials ) ) );
  }

  @api stepTwo()
  {
    console.log(`%c This is the complaint: %c${this.complaint}`, 'color:red;', 'color:green;');
  }

  @api buildNewERP()
  {
    this._erpCopyFields.forEach( field => {
      this.newERP[ field ] = this.retailERP[field]
    });
    this.newERP.Stage__c = 'Pending Diagnostic';
    this.newERP.Job_Status__c = 'Boat Required';
    this.newERP.Original_ERP__c = this.retailERP.Id;
    console.log( this.newERP );

    this.newTask = {
      Cause__c: this.taskCause,
      Name: this.retailERP.RecordType.Name + ' - Back Order',
      DisplayOnCustomerInvoice__c: true
    };
    console.log( this.newTask );
    let totalCost = 0;
    this.newMaterials = this.transferredMaterials.reduce( ( newMaterials, material ) => {
      if( material.quantityTransferred > 0 )
      {
        newMaterials.push({
          AcctSeedERP__Product__c: material.AcctSeedERP__Product__c,
          AcctSeedERP__Quantity_Per_Unit__c: material.quantityTransferred,
          GMBLASERP__Unit_Price__c: material.GMBLASERP__Unit_Price__c,
          GMBLASERP__Price_Override__c: material.GMBLASERP__Price_Override__c,
          AcctSeedERP__Comment__c: material.AcctSeedERP__Comment__c,
          AcctSeedERP__Product__r: {
            Name: material.AcctSeedERP__Product__r.Name
          }
        });
        totalCost += material.GMBLASERP__Unit_Price__c;
      }
      return newMaterials;
    }, [] );
    this.newMaterials.push({
      AcctSeedERP__Product__c: this._creditProductId,
      AcctSeedERP__Quantity_Per_Unit__c: 1,
      GMBLASERP__Unit_Price__c: -1 * totalCost,
      GMBLASERP__Price_Override__c: true,
      AcctSeedERP__Comment__c: 'Back Order Credit',
      AcctSeedERP__Product__r: {
        Name: 'Back Order Credit'
      },
    })
    console.log( this.newMaterials );
  }

  @api createBackOrderRecords()
  {
    return new Promise( (resolve, reject) => {
      let mats = this.newMaterials.reduce( (result, material) => {
        let m = {...material};
        delete m.AcctSeedERP__Product__r;
        result.push( m );
        return result;
       }, [] );
      console.log( mats );
      createRecords( {
        erp: this.newERP,
        task: this.newTask,
        materials: mats
      })
      .then( result => {
        console.log( JSON.parse(JSON.stringify(result)) );
        resolve();
      })
      .catch( error => {
        reject( error );
      })
    })
  }

  get isStepOne()
  {
    return this.currentStep === 0;
  }

  get isStepTwo()
  {
    return this.currentStep === 1;
  }

  get isStepThree()
  {
    return this.currentStep === 2;
  }

  get isStepFour()
  {
    return this.currentStep === 3;
  }

  updateMaterialQuantity( event )
  {
   let matId = event.target.dataset.materialId;
   let mats = JSON.parse( JSON.stringify(this.materials) );
   mats.forEach( mat => {
     if( mat.Id === matId )
     {
       mat.quantityTransferred = parseFloat( event.target.value );
     }
   });
   this.materials = mats;
  }

  updateInput( event )
  {
    let name = event.target.name;
    switch( name )
    {
      case 'material':
        this.updateMaterialQuantity(  event );
        break;
      default:
        this[name] = event.target.value;
    }
  }

}