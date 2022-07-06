/**
 * Created by dave on 2020-11-19.
 */

import { LightningElement, api, track, wire } from 'lwc';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { errorToast, successToast, warningToast, reduceErrors } from 'c/utils';
import getLocations from '@salesforce/apex/ProductTransferTool_Controller.getWorkOrderAndUserLocations';
import fetchWOLIs from '@salesforce/apex/ProductTransferTool_Controller.fetchWorkOrderLineItems';
import fetchProductsRequired from '@salesforce/apex/ProductTransferTool_Controller.fetchRequiredProducts';
import fetchProductsForReturn from '@salesforce/apex/ProductTransferTool_Controller.fetchProductsForReturn';
import transferSingle from '@salesforce/apex/ProductTransferTool_Controller.transferSingle';
import transferMultiple from '@salesforce/apex/ProductTransferTool_Controller.transferMultiple';
import createProductRequired from '@salesforce/apex/ProductTransferTool_Controller.createProductRequired';

export default class FslTransferTool extends LightningElement {

  @api recordId;
  @api inMobileDevice;
  @track transferType;
  @track products=[];
  @track selectedWOLI;
  @track selectedProduct;
  @track productQuantity;

  /* Private Properties */
  _locations;
  _locationMap=[];
  _wolis;
  _spinner;
  _sourceLocation;
  _destinationLocation;

  /* Template Properties */
  woliSelectOptions;
  displayMenu=false;
  productsLoaded=false;
  allowTransferAll=false;
  displayLocationSelector=false;
  displayNewProductRequired=false;
  sourceOptions;
  destinationOptions;
  selectLocationTitle;
  sourceSelectLabel;
  destinationSelectLabel;
  productSearchReturnFields = ['Name', 'ProductCode'];
  productSearchFilterFields = ['Name', 'ProductCode', 'Description'];


  async connectedCallback()
  {
    try
    {
      this._locations = await getLocations( { workOrderId: this.recordId } );
      console.log('connectedCallback');
      console.log( JSON.parse( JSON.stringify( this._locations ) ) );
      this.init();
    }
    catch( err )
    {
      errorToast( this, reduceErrors( err )[0] );
    }
  }

  get componentClassName()
  {
    return this.inMobileDevice ? 'transfer-tool mobile-view' : 'transfer-tool desktop-view';
  }

  get sourceName()
  {
    return this._sourceLocation.Name;
  }

  get destinationName()
  {
    return this._destinationLocation.Name;
  }

  get technicianName()
  {
    return this._locations.employeeLocations !== null &&
           this._locations.employeeLocations.length === 1 ?
             this._locations.employeeLocations[0].Name :
             'Technician';
  }

  get showBinLocations()
  {
    return this._sourceLocation !== null &&
           this._sourceLocation.LocationType === 'Warehouse';
  }

  get showSourceSelect()
  {
    return this.sourceOptions !== undefined && this._sourceLocation === undefined;
  }

  get showDestinationSelect()
  {
    return this.destinationOptions !== undefined &&
           this._destinationLocation === undefined &&
           this._sourceLocation !== undefined;
  }

  get showStandardTable()
  {
    return this.products !== null &&
           this.products.length > 0  &&
           this.transferType !== 'return';

  }

  get showReturnTable()
  {
    const r = this.products !== null &&
           this.products.length > 0  &&
           this.transferType === 'return';
    return r;
  }

  get showWoliSelector()
  {
    return this.woliSelectOptions !== undefined &&
           this.woliSelectOptions.length > 0 &&
           this.selectedWOLI === undefined;
  }

  get showProductSelector()
  {
    return this.selectedWOLI !== undefined;
  }

  get canCreateProductRequired()
  {
    let r = ( this.selectedWOLI !== undefined &&
              this.selectedProduct !== undefined &&
              this.productQuantity !== undefined &&
              this.productQuantity > 0 );
    return !r;
  }

  get selectedProductValue(){
    return this.selectedProduct === undefined ? '' : this.selectedProduct.Name
  }

  init()
  {
    if( this._locations != null )
    {
      const locs = {...this._locations};
      this._locationMap.push({
        id: locs.userBaseLocation.Id,
        location: locs.userBaseLocation
      });
      this._locationMap.push({
        id: locs.workOrderLocation.Id,
        location: locs.workOrderLocation
      });
      if( Object.keys( this._locationMap ).indexOf( this.warehouseLocation ) < 0 )
      {
        this._locationMap.push({
          id: locs.userBaseLocation.Id,
          location: locs.userBaseLocation
        });
      }
      this._locationMap.push({
       id: locs.workOrderPickAndPackLocation.Id,
       location: locs.workOrderPickAndPackLocation
      });
      locs.employeeLocations.reduce( ( acc, loc ) => {
        acc.push( {
          id: loc.Id,
          location: loc
        });
        return acc;
      }, this._locationMap );
      this.displayMenu = true;
      this.toggleSpinner( false );
    }
  }

  handleCancel()
  {
    this._sourceLocation = undefined;
    this._destinationLocation = undefined;
    this._wolis = undefined;
    this.products = [];
    this.displayMenu = true;
    this.allowTransferAll = false;
    this.productsLoaded = false;
    this.displayNewProductRequired = false;
    this.woliSelectOptions = undefined;
    this.selectedWOLI = undefined;
    this.sourceOptions = undefined;
    this.destinationOptions = undefined;
    this.selectLocationTitle = undefined;
    this.sourceSelectLabel = undefined;
    this.destinationSelectLabel = undefined;
    this.selectedProduct = undefined;
    this.productQuantity = undefined;
  }

  handleAction( event )
  {
    this.transferType = event.currentTarget.dataset.transferType;
    this.displayMenu = false;
    switch( this.transferType )
    {
      case 'pickAndPack':
        this.handlePickAndPack();
        break;
      case 'distribute':
        this.handleDistribute();
        break;
      case 'return':
        this.handleReturn();
        break;
      case 'newProductRequired':
        this.handleNewProductRequired();
        break;
    }
  }

  handlePickAndPack()
  {
    this._sourceLocation = this._locations.workOrderLocation;
    this._destinationLocation = this._locations.workOrderPickAndPackLocation
    this.fetchProductList();
  }

  handleDistribute()
  {
    if( this._locations.employeeLocations.length === 0 )
    {
      this.transferType = undefined;
      this.displayMenu = true;
      errorToast(
        this,
        'This Work Order is currently either not scheduled or no assigned to a Technician',
        'You can not hand out items!'
      );
    }
    else
    {
      this.selectLocationTitle = "Where are the the items coming from?";
      this.sourceSelectLabel = "Select Item's Current Location";
      this.sourceOptions = [];
      console.log( JSON.parse( JSON.stringify( this._locations ) ) );
      this.sourceOptions.push( {
        label: this._locations.workOrderLocation.Name,
        value: this._locations.workOrderLocation.Id,
        type: this._locations.workOrderLocation.LocationType
      });
      this.sourceOptions.push( {
        label: this._locations.workOrderPickAndPackLocation.Name,
        value: this._locations.workOrderPickAndPackLocation.Id,
        type: this._locations.workOrderPickAndPackLocation.LocationType
      });
//      this._sourceLocation = this._locations.workOrderPickAndPackLocation;
      this.allowTransferAll = true;
      if( this._locations.employeeLocations.length === 1 )
      {
        this._destinationLocation = this._locations.employeeLocations[0];
        //this.fetchProductList();
      }
      else
      {
        //this.selectLocationTitle = 'Who are you handing these part out to?';
        this.destinationSelectLabel = 'Select Employee';
        this.destinationOptions = this._locations.employeeLocations.reduce(
          ( acc, loc ) => {
            acc.push({
              label: loc.Name,
              value: loc.Id,
              type: loc.LocationType
            });
            return acc;
          },
          []
        );
        //this.displayLocationSelector = true;
      }
      this.displayLocationSelector = true;
    }

  }

  handleReturn()
  {
    this.selectLocationTitle = "Where are the the items coming from you wish to return to Inventory?";
    this.sourceSelectLabel = "Select Item's Current Location";
    this.sourceOptions = this._locations.employeeLocations.reduce(
      ( acc, loc ) => {
       acc.push({
         label: loc.Name,
         value: loc.Id,
         type: loc.LocationType
       });
       return acc;
      },
      []
   );
   this.sourceOptions.push( {
     label: this._locations.workOrderPickAndPackLocation.Name,
     value: this._locations.workOrderPickAndPackLocation.Id,
     type: this._locations.workOrderPickAndPackLocation.LocationType
   } );
   this._destinationLocation = this._locations.workOrderLocation;
   this.displayLocationSelector = true;
  }

  async handleNewProductRequired()
  {
    this.toggleSpinner( true );
    try
    {
      this._wolis = await fetchWOLIs( {workOrderId: this.recordId} );
      this.woliSelectOptions = this._wolis.reduce( (acc, woli) => {
        acc.push({
          label: `${woli.LineItemNumber}-${woli.Description}`,
          value: woli.Id
        });
        return acc;
      }, [] );
      this.displayNewProductRequired = true;
    }
    catch( error )
    {
      errorToast( this, reduceErrors( error )[0] );
      this.handleCancel();
    }
    this.toggleSpinner( false );
  }

  handleLocationChange( event )
  {
    const locType = event.currentTarget.dataset.locationType,
          value = event.detail.value;
    const result = this._locationMap.filter( loc => loc.id === value );
    if( locType === 'source' ) this._sourceLocation = result[0].location;
    if( locType === 'destination' ) this._destinationLocation = result[0].location;
    if( this._sourceLocation && this._destinationLocation )
    {
      this.displayLocationSelector = false;
      if( this.transferType === 'return' )
        this.fetchProductListForReturn();
      else
        this.fetchProductList();
    }
  }

  handleWoliChange( event )
  {
    const woliId = event.detail.value;
    this.selectedWOLI = this._wolis.filter( woli => woli.Id === woliId )[0];
  }

  fetchProductList()
  {
    this.toggleSpinner( true );
    const params = {
      workOrderId: this.recordId,
      sourceLocationId: this._sourceLocation.Id,
      destinationLocationId: this._destinationLocation.Id
    };

    fetchProductsRequired( { jsonParams: JSON.stringify(params) } )
    .then( result => {
      if( result.length === 0 )
      {
        this.handleAllTransfersComplete();
      }
      else
      {
        console.log( JSON.parse(JSON.stringify(result)));
        this.products =  result;
        this.productsLoaded = true;
      }
    })
    .catch( err => {
      errorToast( this, reduceErrors( err )[0] );
    })
    .finally( () => {
      this.toggleSpinner( false );
    });
  }

  handleProductSelect( event )
  {
    console.log( JSON.parse( JSON.stringify( event.detail.value ) ) );
    this.selectedProduct = event.detail.value;
    this.template.querySelector('.product-required-quantity').focus();
  }

  handleProductValueChange( event )
  {
    this.productQuantity = event.detail.value;
  }

  async fetchProductListForReturn()
  {
    this.toggleSpinner( true );
    try
    {
      this.products = await fetchProductsForReturn( {
        sourceLocationId: this._sourceLocation.Id,
        destinationLocationId: this._destinationLocation.Id
      });
      this.productsLoaded = true;
    }
    catch( err )
    {
      errorToast( this, reduceErrors( err )[0] );
    }
    this.toggleSpinner( false );
  }

  async handleSingleTransfer( event )
  {
    this.toggleSpinner( true );
    let value = event.detail,
        completeTransfer = this.transferType === 'return' ?
         value.quantityAvailable === value.quantityTransferred :
         value.quantityRequired === value.quantityTransferred;

    try
    {
      await transferSingle( { transfer: value } )
      this.toggleSpinner( false );
      const comp = this.template.querySelector(`c-product-transfer-tool-line[data-id="${value.id}"]`);
      await comp.transferSuccess( value.quantityTransferred );
      if( completeTransfer )
        this.products = this.products.filter( p => p.id !== value.id );
      if( this.products.length === 0 )
        this.handleAllTransfersComplete();
    }
    catch( err )
    {
      this.toggleSpinner( false );
      errorToast( this, reduceErrors( err )[0] );
    }
  }

  async handleTransferAll()
  {
    this.toggleSpinner( true );
    let prods = this.products.filter( prod => prod.quantityAvailable >= prod.quantityRequired );
    prods = prods.reduce( ( acc, prod ) => {
      prod.quantityTransferred = prod.quantityRequired;
      acc.push( prod );
      return acc;
    }, [] );
    try
    {
      await transferMultiple( { transfers: prods} );
      if( this.products.length === prods.length )
      {
        const msg = `All items transferred to ${this._destinationLocation.Name}`;
        successToast( this, msg  );
        this.handleCancel();
        this.toggleSpinner( false );
      }
      else
      {
        warningToast( this,
                      ` Transferred ${prods.length} out of ${this.products.length} items`,
                      'Partial Transfer Success' );
        this.fetchProductList();
      }
    }
    catch( err )
    {
      errorToast( this, reduceErrors( err )[0] );
      this.toggleSpinner( false );
    }
  }

  async handleCreateProductRequired()
  {
    this.toggleSpinner( true );
    try
    {
      let productRequired = await createProductRequired({
        woliId: this.selectedWOLI.Id,
        productId: this.selectedProduct.Id,
        quantity: this.productQuantity
      });
      this.handleCancel();
    }
    catch( error )
    {
      errorToast( this, reduceErrors( error )[0] );
    }
    this.toggleSpinner( false );
  }

  handleAllTransfersComplete()
  {
    let msg;
    switch( this.transferType )
    {
      case 'pickAndPack':
        msg = 'Pick and Pack is Complete';
        break;
      case 'distribute':
        msg = 'All items have been handed out';
        break
      default:
        msg = 'Transfers are Complete';
    }
    warningToast( this, msg, 'All done!' );
    this.handleCancel();
  }

  toggleSpinner( open )
  {
    if( this._spinner === undefined )
      this._spinner = this.template.querySelector("c-legend-spinner");

    open ? this._spinner.open() : this._spinner.close();
  }

}