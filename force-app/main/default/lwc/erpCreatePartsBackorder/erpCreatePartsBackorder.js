/**
 * Created by dave on 2021-03-29.
 */

import { LightningElement, api, wire, track } from 'lwc';
import fetchMaterials from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.fetchMaterials';

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
    console.log( this.newERP );

    this.newTask = {
      Cause__c: this.taskCause,
      Name: 'Retail Sale - We Owe'
    };
    console.log( this.newTask );

    this.transferredMaterials.reduce( ( newMaterials, material ) => {
      if( material.quantityTransferred > 0 )
      {
        newMaterials.push({
          AcctSeedERP__Product__c: material.AcctSeedERP__Product__c,
          AcctSeedERP__Quantity_Per_Unit__c: material.quantityTransferred,
          GMBLASERP__Unit_Price__c: material.GMBLASERP__Unit_Price__c,
          GMBLASERP__Price_Override__c: material.GMBLASERP__Price_Override__c,
          AcctSeedERP__Comment__c: material.AcctSeedERP__Comment__c,
          _temp_ProductName: material.AcctSeedERP__Product__r.Name,
        })
      }
      return newMaterials;
    }, this.newMaterials );
    console.log( this.newMaterials );
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