/**
 * Created by dave on 2021-03-29.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { gen8DigitId, reduceErrors, errorToast } from 'c/utils';
import fetchMaterials from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.fetchMaterials';
import findCases from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.findPartsRequestCases';
import buildRecords from '@salesforce/apex/ERP_CreatePartsBackOrder_Controller.buildBackOrderERP';
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
  originalMaterialToDelete;
  originalMaterialToUpdate;
  retailERP;
  newERP={};
  newTask={};
  newMaterials=[];
  selectedCases=[];

  newCommissionLines=[];

  newMaterialsForOriginal=[];

  _originalSaleType;
  _kitContents;
  _creditProductId;
  _prepaidProductId;
  _stepOneValid=true;

  @wire( fetchMaterials, { recordId: '$recordId' } )
  wiredFetchMaterials( result )
  {
    if( result.data )
    {
      result.data.materials.forEach( mat => {
        if( mat.AcctSeedERP__Quantity_Per_Unit__c !== mat.AcctSeedERP__Quantity_Allocated__c )
        {
          let m = JSON.parse( JSON.stringify(mat) );
          m.quantityTransferred = mat.AcctSeedERP__Quantity_Per_Unit__c - mat.AcctSeedERP__Quantity_Allocated__c;
          m.isSelected = m.quantityTransferred > 0;
          this.materials.set( m.Id, m );
        }
      })

      this._groupKitParts();

      this.retailERP = result.data.retailERP;
      this._kitContents = result.data.kitContents;
      this._originalSaleType = result.data.saleType;
      this._creditProductId = result.data.creditProductId;
      this._prepaidProductId = result.data.prepaidProductId;
      this.dispatchEvent(
        new CustomEvent('initialized')
      );
    }
    if( result.error )
    {
      errorToast( this, reduceErrors(error).join(', ') );
    }
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
        if( result.length > 0 )
        {
          this.partsCases = [...result].reduce( (acc, pCase) => {
            pCase.isSelected = true;
            acc.push(pCase);
            return acc;
          }, [] );
          return Promise.resolve(2);
        }
        return this.buildNewERP();
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
      let materialMap = new Object();
      this.transferredMaterials.forEach( mat => {
        materialMap[ mat.Id ] = { quantity: mat.quantityTransferred, parentMatId: mat.Material__c };
      });
      let params = {
        originalErpId: this.retailERP.Id,
        transferredQuantityByMaterialId: JSON.stringify( materialMap ),
        taskCause: this.taskCause
      };
      buildRecords( params )
      .then( result => {
        this.newERP = result.erp;
        this.newTask = result.task;
        this.newMaterials = result.materials.reduce( (acc, mat) => {
          mat.Id = gen8DigitId();
          mat.lineTotal = mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
          acc.push( mat );
          return acc;
        }, []);
        if( this.partsCases )
        {
          this.selectedCases = this.partsCases.filter( pc => pc.isSelected );
        }
        resolve(3);
      })
      .catch( error => {
        reject( reduceErrors( error ).join(', ') );
      });
    });
  }

  @api initializeChangesToOriginalOrder()
  {
    if( this._originalSaleType === 'retail' )
    {
      const retailTask = this._determineProjectTaskForRetail();
      this._buildMaterialsForOriginalOrderRetail( retailTask );
      return this._buildCommissionLineForRetail();
    }
    if( this._originalSaleType === 'service' )
    {
      //TODO: figure this out
    }
  }

  @api saveAllChanges()
  {
    return this.createBackOrderRecords()
    .then( result => {
      this.dispatchEvent(new CustomEvent('backordercreatesuccess') );
      return this.updateOriginalOrder( result.erp.Name );
    })
    .catch( error => {
      return Promise.reject( reduceErrors(error).join(', ' ) );
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

  get isStepFive()
  {
    return this.currentStep === 4;
  }

  updateInput( event )
  {
    let name = event.target.name;
    switch( name )
    {
      case 'material':
        this._updateMaterialQuantity( event );
        break;
      default:
        this[name] = event.target.value;
    }
  }

  createBackOrderRecords()
  {
    return new Promise( (resolve, reject) => {
      let mats = this.newMaterials.reduce( (result, material) => {
        const { Id, lineTotal, ...m } = material;
        result.push( m );
        return result;
       }, [] );
      let caseIds = this.selectedCases.map( c => c.Id );
      const { Serial_Number__r, ...erp } = this.newERP;
      createRecords( {
        erp: erp,
        task: this.newTask,
        materials: mats,
        caseIds: caseIds
      })
      .then( result => {
        resolve(result);
      })
      .catch( error => {
        reject( reduceErrors(error).join(', ') );
      })
    });
  }

  updateOriginalOrder( newErpName )
  {
    return new Promise( (resolve, reject) => {
      let params = {};
      let materialMap = new Object();
      let standaloneKitPartMaterialsIds = this.newMaterialsForOriginal.map( nm => nm.Id );
      this.transferredMaterials.forEach( mat => {
        if( standaloneKitPartMaterialsIds.indexOf( mat.Id) < 0 )
        {
          materialMap[ mat.Id ] = mat.quantityTransferred;
        }
      });
      params.quantityTransferredByMatId = JSON.stringify( materialMap );
      params.newMaterials = this.newMaterialsForOriginal.reduce( (acc, mat) => {
        mat.AcctSeedERP__Comment__c = newErpName;
        const { AcctSeedERP__Product__r, AcctSeedERP__Project_Task__r, Id, ...m } = mat;
        acc.push( m );
        return acc;
      }, []);
      params.newCommissionLines = this.newCommissionLines.reduce( (acc, commLine) => {
        commLine.Comment__c = newErpName;
        const { CommissionRecord2__r, ...cli } = commLine;
        acc.push( cli );
        return acc;
      }, []);
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

   _groupKitParts()
  {
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

  _determineProjectTaskForRetail()
  {
    return this.retailERP.AcctSeed__Project_Tasks__r
      .filter( task => task.Is_Retail_Boat_Sale__c )[0];
  }

  _buildMaterialsForOriginalOrderRetail( task )
  {
    let materials = [];
    this.originalMaterialToUpdate = undefined;
    this.originalMaterialToDelete = undefined;
    this.newMaterialsForOriginal = [];
    let offsetCost = 0;
    let parentIds = this.transferredMaterials.filter( m => m.Material__c == null ).map( m => m.Id );

    let addToDelete = ( material ) =>
    {
      if( typeof( this.originalMaterialToDelete ) === 'undefined' )
      {
        this.originalMaterialToDelete = new Array();
      }
      this.originalMaterialToDelete.push( material );
    }
    let addToUpdate = ( material ) =>
    {
      if( typeof( this.originalMaterialToUpdate) === 'undefined' )
      {
        this.originalMaterialToUpdate = new Array();
      }
      this.originalMaterialToUpdate.push( {
        id: material.Id,
        originalQuantity: material.AcctSeedERP__Quantity_Per_Unit__c,
        newQuantity: material.AcctSeedERP__Quantity_Per_Unit__c - material.quantityTransferred,
        productName: material.AcctSeedERP__Product__r.Name
      });
    }
    let addToNew = ( material ) => {
      this.newMaterialsForOriginal.push( material );
    }
    /* THE RULES
      No Material__c AKA a parent either delete or update quantity
      Has Material__c AKA kitPart AND Material__c is in parentIds
        - do whatever you did to the parent
      ID Material__c !IN parentIds create a new line with negative quantity

    */

    this.transferredMaterials.forEach( mat => {
      offsetCost += (mat.quantityTransferred * mat.GMBLASERP__Unit_Price__c);
      if( mat.quantityTransferred === mat.AcctSeedERP__Quantity_Per_Unit__c )
      {
        addToDelete( mat );
      }
      if( mat.quantityTransferred < mat.AcctSeedERP__Quantity_Per_Unit__c )
      {
        if( mat.Material__c && parentIds.indexOf( mat.Material__c ) < 0 )
        {
          let offsetMat = {...mat};
          offsetMat.AcctSeedERP__Quantity_Per_Unit__c = -1 * mat.quantityTransferred;
          addToNew( offsetMat );
        }
        else
        {
          addToUpdate( mat );
        }
      }
    });
    addToNew({
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
    let mats = this.transferredMaterials.reduce( (acc, mat) => {
      mat.AcctSeedERP__Quantity_Per_Unit__c = mat.quantityTransferred;
      acc.push( mat );
      return acc;
    },[]);
    return new Promise( (resolve, reject) => {
      buildCommissionLines( { materials: mats } )
      .then( result => {
        console.log('COMMISSION LINES');
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

   _updateMaterialQuantity( event )
  {
    this._stepOneValid = true;
    const quantity = parseFloat( event.target.value );
    const matId = event.target.dataset.materialId;
    const parentId = event.target.dataset.parentMaterialId;
    this.materials.get( matId ).quantityTransferred = quantity;
    this.materials.get( matId ).isSelected = quantity > 0;
    const kitMap = this._getKitMap( matId );
    if( kitMap )
    {
      this.groupedMaterials.forEach( parentMat => {
        if( parentMat.Id === matId )
        {
          parentMat.kitParts.forEach( kitMat => {
            kitMat.quantityTransferred = kitMap.get(kitMat.AcctSeedERP__Product__c) * quantity;
            this.materials.get( kitMat.Id ).quantityTransferred = kitMap.get(kitMat.AcctSeedERP__Product__c) * quantity;
            this.materials.get( kitMat.Id ).isSelected = kitMap.get(kitMat.AcctSeedERP__Product__c) * quantity > 0;
          })
        }
      });
    }
    event.target.reportValidity();
    this.dispatchEvent(
      new CustomEvent('validitychange', {
        detail: {
          valid: event.target.checkValidity()
        }
      })
    );
  }

  _getKitMap( matId )
  {
    const prodId = this.materials.get( matId ).AcctSeedERP__Product__c;
    if( Object.keys( this._kitContents ).indexOf( prodId ) < 0 ) return null;
    let kitMap = new Map();
    Object.keys( this._kitContents[prodId] ).forEach( k => {
      kitMap.set( k, this._kitContents[prodId][k] );
    });
    return kitMap;
  }

}