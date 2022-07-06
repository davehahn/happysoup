/**
 * Created by dave on 2020-11-17.
 */

import { LightningElement, api, track } from 'lwc';

export default class ProductTransferToolLine extends LightningElement {

  @track transferLine;

  @api
  get productLine()
  {
    return this.transferLine();
  }
  set productLine(value)
  {
    this.transferLine = {...value};
  }

  @api showRequired=false;
  @api showWarehouseLocations=false;

  @api transferSuccess( quantity )
  {
    console.log( `successfully transferred ${quantity}` );
    let row = this.template.querySelector('tr');
    return new Promise( (resolve, reject) => {
      if( ( this.transferLine.quantityRequired === quantity && this.showRequired ) ||
          ( this.transferLine.quantityAvailable  === quantity && !this.showRequired ) )
      {
        row.classList.add('fade');
        setTimeout( () => {
          row.classList.add('shrink');
          setTimeout( () => { resolve() }, 500);
        }, 500 );
      }
      else
      {
        if( this.showRequired )
          this.transferLine.quantityRequired = this.transferLine.quantityRequired - quantity;
        this.transferLine.quantityAvailable = this.transferLine.quantityAvailable - quantity;
        this.transferLine.quantityTransferred = 0;
        row.classList.add('highlight');
        setTimeout( () => {
          row.classList.remove('highlight');
          setTimeout( () => { resolve() }, 500);
        }, 500 );
      }
    });
  }



//  get loaded()
//  {
//    console.log( this.transferLine );
//    console.log( typeof(this.transferLine ) !== 'undefined' && this.transferLine !== null );
//    return typeof( this.transferLine ) !== 'undefined' && this.transferLine !== null;
//  }

  get canSubmit()
  {
    return !( Object.keys( this.transferLine ).indexOf( 'quantityTransferred' ) >= 0 &&
      this.transferLine.quantityTransferred > 0 &&
      this.transferLine.quantityTransferred <= this.transferLine.quantityAvailable &&
      ( ( this.transferLine.quantityTransferred <= this.transferLine.quantityRequired &&
          this.showRequired ) ||
        ( this.transferLine.quantityTransferred <= this.transferLine.quantityAvailable &&
          !this.showRequired )
      )
    );
  }

  handleTransferQtyChange( event )
  {
    console.log('handleTransferQtyChange');
    console.log( parseFloat( event.target.value ) );
    this.populateTransferQuantity( event.target.value );
  }

  fillTransferQuantity( event )
  {
    event.preventDefault();
    this.populateTransferQuantity( event.currentTarget.dataset.quantity );
  }

  populateTransferQuantity( quantity )
  {
    console.log( JSON.parse( JSON.stringify( this.transferLine ) ) );
    this.transferLine.quantityTransferred = parseFloat( quantity );
  }

  handleTransfer()
  {
    console.log(JSON.parse(JSON.stringify( this.transferLine)));
    const evt = new CustomEvent('transfer', { detail: this.transferLine } );
    this.dispatchEvent( evt );
  }
}