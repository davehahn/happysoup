/**
 * Created by dave on 2020-02-11.
 */

import { LightningElement, api } from 'lwc';

export default class CommissionLineItemRow extends LightningElement {

  @api lineItem;
  @api lineNumber;
  @api isChildRow=false;
  @api renderRatePaymentColumns;

  get rowClass()
  {
    return this.isChildRow ? 'kit-row' : 'row';
  }

  get itemNumber()
  {
    return this.isChildRow ? '' : this.lineNumber+1;
  }

  get shouldDisplayComment()
  {
    return this.lineItem.comment && this.lineItem.description !== this.lineItem.comment;
  }

  get renderEachSalePrice()
  {
    return this.lineItem.quantity > 1 && this.lineItem.salePrice > 0;
  }

  get renderEachUnitCost()
  {
    return this.lineItem.quantity > 1 && this.lineItem.unitCost > 0;
  }

  get hasKitParts()
  {
    return this.lineItem.kitParts.length > 0;
  }

  handleMenuClick( event )
  {
    this.dispatchEvent(
      new CustomEvent( 'lineaction', {
        detail: {
          action: event.target.value,
          recordId: this.lineItem.id
        }
      })
    );
  }

}