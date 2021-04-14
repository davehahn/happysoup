/**
 * Created by dave on 2021-03-29.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { gen8DigitId, reduceErrors } from 'c/utils';
import fetchMaterials from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.fetchMaterials';
import findCases from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.findPartsRequestCases';
import createRecords from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.createBackOrderERP';
import buildCommissionLines from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.buildCommissionLines';
import updateOriginalSale from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.updateOriginalSale';

export default class ErpCreatePartsBackorder extends LightningElement {

  @api recordId;
  @api currentStep;

  @track materials = new Map();
  @track taskCause;
  @track groupedMaterials=[];
  @track partsCases;

  transferredMaterials=[];
  retailERP;
  newERP={};
  newTask={};
  newMaterials=[];
  selectedCases=[];

  newCommissionLines=[];

  prepaidOffsetMaterials=[];

  _originalSaleType;
  _creditProductId;
  _prepaidProductId;
  _erpCopyFields = [
    'AcctSeed__Account__c',
    'GMBLASERP__Warehouse__c',
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
      result.data.materials.forEach( mat => {
        if( mat.AcctSeedERP__Quantity_Per_Unit__c !== mat.AcctSeedERP__Quantity_Allocated__c )
        {
          let m = JSON.parse( JSON.stringify(mat) );
          m.quantityTransferred = mat.AcctSeedERP__Quantity_Per_Unit__c - mat.AcctSeedERP__Quantity_Allocated__c;
          this.materials.set( m.Id, m );
        }
      })

      this._groupKitParts();

      this.retailERP = result.data.retailERP;
      this._originalSaleType = result.data.saleType;
      this._creditProductId = result.data.creditProductId;
      this._prepaidProductId = result.data.prepaidProductId;
      this.dispatchEvent(
        new CustomEvent('initialized')
      );
    }
    if( result.error )
    {
      console.log( result.error );
    }
  }

  _groupKitParts()
  {
    console.log('_groupKitParts()');
    let mats = new Map();
    let children = [];
    for( let mat of this.materials.values() )
    {
      if( mat.Material__c )
      {
        children.push( mat );
      }
      else
      {
        mats.set( mat.Id, mat );
      }
    }
    children.forEach( childMat => {
      if( mats.has( childMat.Material__c ) )
      {
        if( !mats.get(childMat.Material__c).kitParts )
        {
          mats.get(childMat.Material__c).kitParts = [];
        }
        mats.get(childMat.Material__c).kitParts.push( childMat );
      }
    })
    this.groupedMaterials = Array.from( mats.values() );
  }

  @api hasCases()
  {
    return this.partsCases && this.partsCases.length > 0;
  }

  @api stageTransferredMaterials()
  {
    return new Promise( (resolve, reject) => {
      this.transferredMaterials = Array.from( this.materials.values() )
        .filter( mat => mat.quantityTransferred > 0 );
      resolve(1);
    });
  }

  @api findPartsRequestCases()
  {
    return new Promise( (resolve, reject) => {
      let matIds = this.transferredMaterials.map( mat => mat.Id );
      findCases({ originalErpId: this.retailERP.Id, materialIds: matIds })
      .then( result => {
        console.log( JSON.parse(JSON.stringify(result)));
        if( result.length > 0 )
        {
          this.partsCases = [...result].reduce( (acc, pCase) => {
            pCase.isSelected = false;
            acc.push(pCase);
            return acc;
          }, [] );
          return Promise.resolve(2);
        }
        return this.buildNewERP()
      })
      .then( (step) => {
        resolve(step);
      })
      .catch( error => {
        reject( reduceErrors( error ).join(', ') );
      });
    });
  }

  @api buildNewERP()
  {
    return new Promise( (resolve, reject) => {
      this._erpCopyFields.forEach( field => {
        this.newERP[ field ] = this.retailERP[field]
      });
      this.newERP.Stage__c = 'Pending Diagnostic';
      this.newERP.Job_Status__c = 'Boat Required';
      this.newERP.Original_ERP__c = this.retailERP.Id;
      console.log( this.newERP );

      this.newTask = {
        Cause_dh__c: this.taskCause,
        Name: this.retailERP.RecordType.Name + ' - Back Order',
        DisplayOnCustomerInvoice__c: true
      };
      console.log( this.newTask );
      let totalCost = 0;
      this.newMaterials = this.transferredMaterials.reduce( ( newMaterials, material ) => {
        if( material.quantityTransferred > 0 )
        {
          newMaterials.push({
            Id: gen8DigitId(),
            AcctSeedERP__Product__c: material.AcctSeedERP__Product__c,
            AcctSeedERP__Quantity_Per_Unit__c: material.quantityTransferred,
            GMBLASERP__Unit_Price__c: material.GMBLASERP__Unit_Price__c,
            GMBLASERP__Price_Override__c: material.GMBLASERP__Price_Override__c,
            AcctSeedERP__Comment__c: material.AcctSeedERP__Comment__c,
            AcctSeedERP__Product__r: {
              Name: material.AcctSeedERP__Product__r.Name
            }
          });
          totalCost += material.GMBLASERP__Unit_Price__c * material.quantityTransferred;
        }
        return newMaterials;
      }, [] );
      this.newMaterials.push({
        Id: gen8DigitId(),
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
      if( this.partsCases )
      {
        this.selectedCases = this.partsCases.filter( pc => pc.isSelected );
      }
      console.log( this.selectedCases );
      resolve(3);
    });
  }

  @api createBackOrderRecords()
  {
    return new Promise( (resolve, reject) => {
//      setTimeout( () => {
//          resolve();
//      }, 1000 );
      let mats = this.newMaterials.reduce( (result, material) => {
        const { AcctSeedERP__Product__r, Id, ...m } = material;
        result.push( m );
        return result;
       }, [] );
      let caseIds = this.selectedCases.map( c => c.Id );
      createRecords( {
        erp: this.newERP,
        task: this.newTask,
        materials: mats,
        caseIds: caseIds
      })
      .then( result => {
        console.log( JSON.parse(JSON.stringify(result)) );
        resolve();
      })
      .catch( error => {
        reject( error );
      })
    });
  }

  @api initializeChangesToOriginalOrder()
  {
    if( this._originalSaleType === 'retail' )
    {
      const retailTask = this._determineProjectTaskForRetail();
      this._buildOffsetMaterialsForOriginalOrderRetail( retailTask );
      return this._buildCommissionLineForRetail();
    }
    if( this._originalSaleType === 'service' )
    {
      //TODO: figure this out
    }
  }

  @api updateOriginalOrder()
  {
    return new Promise( (resolve, reject) => {
      let params = {};
      params.deleteMaterialIds = this.transferredMaterials.reduce( (acc, mat) => {
        acc.push( mat.Id );
        return acc;
      }, [] );
      params.newMaterials = this.prepaidOffsetMaterials.reduce( (acc, mat) => {
//        let m = {...mat};
//        delete m.AcctSeedERP__Product__r;
//        delete m.AcctSeedERP__Project_Task__r
//        delete m.Id;
        const { AcctSeedERP__Product__r, AcctSeedERP__Project_Task__r, Id, ...m } = mat;
        acc.push( m );
        return acc;
      }, []);
      params.newCommissionLines = this.newCommissionLines.reduce( (acc, commLine) => {
//        let cli = {...commLine};
//        delete cli.CommissionRecord2__r;
        const { CommissionRecord2__r, ...cli } = commLine;
        acc.push( cli );
        return acc;
      }, []);
      console.log(JSON.parse(JSON.stringify(params)));
      updateOriginalSale( params )
      .then( () => {
        resolve();
      })
      .catch( error => {
        reject( reduceErrors(error).join(', ') );
      })
    });
  }

  handleCaseSelect( event )
  {
    const caseId = event.target.dataset.value;
    this.partsCases.forEach( pc => {
      if( pc.Id === caseId )
      {
        pc.isSelected = !pc.isSelected;
      }
    });
  }

  _determineProjectTaskForRetail()
  {
    return this.retailERP.AcctSeed__Project_Tasks__r
      .filter( task => task.Is_Retail_Boat_Sale__c )[0];
  }

  _buildOffsetMaterialsForOriginalOrderRetail( task )
  {
    let materials = [];
    let offsetCost = 0;

    this.transferredMaterials.forEach( mat => offsetCost += (mat.quantityTransferred * mat.GMBLASERP__Unit_Price__c) );
    this.prepaidOffsetMaterials.push({
      Id: gen8DigitId(),
      AcctSeedERP__Product__c: this._prepaidProductId,
      AcctSeedERP__Project__c: task.AcctSeed__Project__c,
      AcctSeedERP__Project_Task__c: task.Id,
      AcctSeedERP__Quantity_Per_Unit__c: 1,
      GMBLASERP__Unit_Price__c: offsetCost,
      GMBLASERP__Price_Override__c: true,
      AcctSeedERP__Comment__c: 'Prepaid Back Ordered Items',
      AcctSeedERP__Product__r: {
        Name: 'Prepaid Back Ordered Items'
      },
      AcctSeedERP__Project_Task__r: {
        Name: task.Name
      }
    });
  }

  _buildOffsetMaterialsForOriginalOrderService()
  {

  }

  _buildCommissionLineForRetail()
  {
    return new Promise( (resolve, reject) => {
      buildCommissionLines( { materials: this.transferredMaterials } )
      .then( result => {
        console.log( JSON.parse(JSON.stringify(result)));
        this.newCommissionLines = result;
        resolve(4);
      })
      .catch( error => {
        reject( error );
      })
    })
  }

  _buildCommissionLinesForService()
  {
    return Promise.resolve();
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

  get isStepFive()
  {
    return this.currentStep === 4;
  }

  updateMaterialQuantity( event )
  {
   let matId = event.target.dataset.materialId;
   this.materials.get( matId ).quantityTransferred = parseFloat( event.target.value );
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