({
	buildSaleItem : function( option, isIncluded )
  {
    return {
      quantity: option.quantitySelected,
      salePrice: isIncluded ? 0 : option.retailPrice,
      partnerPrice: option.partnerPrice,
      productId: option.prod.Id,
      productName: option.prod.Name,
      pricebookEntryId: option.retailPricebookEntryId,
      parentProductId: option.parentProductId,
      subSaleItems: [],
      taxable: option.taxable,
      lineTotal: isIncluded ? 0 : option.quantitySelected * option.retailPrice
    }
	}
})