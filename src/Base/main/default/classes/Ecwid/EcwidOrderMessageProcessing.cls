public without sharing class EcwidOrderMessageProcessing {
  public EcwidOrderWrapper order_wrapper = new EcwidOrderWrapper();
  Account account = new Account();

  public EcwidOrderMessageProcessing() {
  }

  public EcwidOrderMessageProcessing(String jsonResponse) {
    this.order_wrapper = EcwidOrderWrapper.parse(jsonResponse);
  }

  /*
   * Build Query based on the field stored in custome meta data
   */
  private String buildQuery(String queryFor, Account account) {
    String query = EcwidRestUtils.dynamicQueryMap.get(queryFor);
    List<Ecwid_Query_Field_Mapping__mdt> lstField = EcwidRestUtils.dynamicQueryFieldMap.get(queryFor);

    for (Ecwid_Query_Field_Mapping__mdt field : lstField) {
      if (query.indexOf(field.MasterLabel) != -1) {
        if (account.get(field.Field_Name__c) != null)
          query = query.replace(field.MasterLabel, String.valueOf(account.get(field.Field_Name__c)));
      }
    }
    return query;
  }

  /*
   * Find the matchnig account with the given criteria
   */
  public List<sObject> findDuplicateAccount() {
    String query = buildQuery('Duplicate Account', this.account);
    try {
      return Database.query(query);
    } catch (Exception e) {
      System.debug('Exception = ' + e);
    }
    return null;
  }

  /*
   * Check the order status coming from Ecwid
   */
  public Boolean checkOrderStatus() {
    if ('DELIVERED'.equalsIgnoreCase(this.order_wrapper.fulfillmentStatus)) {
      return false;
    }
    return true;
  }

  /*
   * Prepare SObject for internal code purpose
   */
  public void prepareAccountObject() {
    this.account.PersonEmail = this.order_wrapper.email;
  }

  /*
   * Update account information if account is present. Information are obtain from Ecwid Response
   */
  public void updateAccount(Account account) {
    try {
      account.PersonEmail = this.order_wrapper.email;
      if (this.order_wrapper.billingPerson != null) {
        account.BillingStreet = this.order_wrapper.billingPerson.street;
        account.BillingCity = this.order_wrapper.billingPerson.city;
        account.BillingState = this.order_wrapper.billingPerson.stateOrProvinceName;
        account.BillingCountry = this.order_wrapper.billingPerson.countryName;
        account.BillingCountryCode = this.order_wrapper.billingPerson.countryCode;
        account.BillingStateCode = this.order_wrapper.billingPerson.stateOrProvinceCode;
        account.BillingPostalCode = this.order_wrapper.billingPerson.postalCode;
        account.Phone = this.order_wrapper.billingPerson.phone;
      }
      if (this.order_wrapper.shippingPerson != null) {
        account.shippingStreet = this.order_wrapper.shippingPerson.street;
        account.shippingCity = this.order_wrapper.shippingPerson.city;
        account.shippingState = this.order_wrapper.shippingPerson.stateOrProvinceName;
        account.shippingCountry = this.order_wrapper.shippingPerson.countryName;
        account.shippingCountryCode = this.order_wrapper.shippingPerson.countryCode;
        account.shippingStateCode = this.order_wrapper.shippingPerson.stateOrProvinceCode;
        account.shippingPostalCode = this.order_wrapper.shippingPerson.postalCode;
        account.Phone = this.order_wrapper.billingPerson.phone;
      }
      update account;
    } catch (Exception e) {
      System.debug('Exception in updateAccount: ' + e.getMessage());
    }
  }

  /*
   * Create Lead
   */
  public Lead ceateLead() {
    Lead lead = new Lead();
    try {
      lead.email = this.order_wrapper.email;

      if (null != this.order_wrapper.billingPerson) {
        lead.LastName = this.order_wrapper.billingPerson.name != null
          ? this.order_wrapper.billingPerson.name
          : this.order_wrapper.email;
        lead.City = this.order_wrapper.billingPerson.city != null ? this.order_wrapper.billingPerson.city : '';
        lead.Street = this.order_wrapper.billingPerson.street != null ? this.order_wrapper.billingPerson.street : '';
        lead.State = this.order_wrapper.billingPerson.stateOrProvinceName != null
          ? this.order_wrapper.billingPerson.stateOrProvinceName
          : '';
        lead.Country = this.order_wrapper.billingPerson.countryName != null
          ? this.order_wrapper.billingPerson.countryName
          : '';
        lead.CountryCode = this.order_wrapper.billingPerson.countryCode != null
          ? this.order_wrapper.billingPerson.countryCode
          : '';
        lead.StateCode = this.order_wrapper.billingPerson.stateOrProvinceCode != null
          ? this.order_wrapper.billingPerson.stateOrProvinceCode
          : '';
        lead.PostalCode = this.order_wrapper.billingPerson.postalCode != null
          ? this.order_wrapper.billingPerson.postalCode
          : '';
        lead.Company = this.order_wrapper.billingPerson.companyName != null
          ? this.order_wrapper.billingPerson.companyName
          : '';
        lead.Phone = this.order_wrapper.billingPerson.phone != null ? this.order_wrapper.billingPerson.phone : '';
      } else {
        lead.LastName = this.order_wrapper.email;
      }
      insert lead;
    } catch (Exception e) {
      System.debug('Exception in updateAccount: ' + e.getMessage());
    }
    return lead;
  }

  /*
   * This function checks whether sales order exists based on the id received from Ecwid
   */
  public List<AcctSeedERP__Sales_Order__c> checkExistingSalesOrder() {
    List<AcctSeedERP__Sales_Order__c> lstSalesOrder = [
      SELECT
        id,
        Ecwid_Order_Id__c,
        AcctSeedERP__Customer__c,
        (
          SELECT
            id,
            AcctSeedERP__Product__c,
            AcctSeedERP__Quantity_Ordered__c,
            AcctSeedERP__Unit_Price__c,
            GMBLASERP__Price_Override__c,
            AcctSeedERP__GL_Account_Variable_3__c
          FROM AcctSeedERP__Sales_Order_Line__r
        )
      FROM AcctSeedERP__Sales_Order__c
      WHERE Ecwid_Order_Id__c = :this.order_wrapper.id
    ];
    return lstSalesOrder;
  }

  public Id getGLV3(Account acc) {
    acc.billingstate = 'Ontario';
    String query = buildQuery('SL GLV3', acc);
    String glv3Id = null;
    List<sObject> sobject_list;
    try {
      sobject_list = Database.query(query);
    } catch (Exception e) {
      System.debug('Exception = ' + e);
    }
    if (sobject_list != null && !sobject_list.isEmpty()) {
      for (Sobject obj : sobject_list) {
        if (obj.get('Name') == 'Others') {
          glv3Id = obj.Id;
        }
        if (obj.get('Name') == acc.billingstate) {
          return obj.Id;
        }
      }
    }
    return glv3Id;
  }

  public AcctSeedERP__Sales_Order__c createSalesOrder(Account acc, AcctSeedERP__Sales_Order__c salesOrder) {
    salesOrder.AcctSeedERP__Customer__c = acc.id;
    salesOrder.Ecwid_Order_Id__c = this.order_wrapper.id;
    salesOrder.Stage__c = this.order_wrapper.fulfillmentStatus;
    if (this.order_wrapper.billingPerson != null) {
      salesOrder.AcctSeedERP__Billing_Street__c = this.order_wrapper.billingPerson.street;
      salesOrder.AcctSeedERP__Billing_City__c = this.order_wrapper.billingPerson.city;
      salesOrder.AcctSeedERP__Billing_State__c = this.order_wrapper.billingPerson.stateOrProvinceName;
      salesOrder.AcctSeedERP__Billing_Country__c = this.order_wrapper.billingPerson.countryName;
      salesOrder.AcctSeedERP__Billing_PostalCode__c = this.order_wrapper.billingPerson.postalCode;
    }

    if (this.order_wrapper.shippingPerson != null) {
      salesOrder.AcctSeedERP__Shipping_Street__c = this.order_wrapper.shippingPerson.street;
      salesOrder.AcctSeedERP__Shipping_City__c = this.order_wrapper.shippingPerson.city;
      salesOrder.AcctSeedERP__Shipping_State__c = this.order_wrapper.shippingPerson.stateOrProvinceName;
      salesOrder.AcctSeedERP__Shipping_Country__c = this.order_wrapper.shippingPerson.countryName;
      salesOrder.AcctSeedERP__Shipping_PostalCode__c = this.order_wrapper.shippingPerson.postalCode;
    }

    if (!String.isEmpty(account.AcctSeed__GL_Account_Variable_3__c)) {
      salesOrder.GL_Account_Variable_3__c = account.AcctSeed__GL_Account_Variable_3__c;
    } else {
      salesOrder.GL_Account_Variable_3__c = getGLV3(account);
    }
    salesOrder.Warehouse__c = EcwidRestUtils.wareHouseId;
    salesOrder.GL_Account_Variable_1__c = EcwidRestUtils.glv1Id;
    salesOrder.GL_Account_Variable_2__c = EcwidRestUtils.glv2Id;
    salesOrder.Payment_Status__c = this.order_wrapper.paymentStatus;
    salesOrder.Ecwid_Store_Id__c = EcwidRestUtils.storeId;

    if (Test.isRunningTest()) {
      AcctSeed__Ledger__c led = [
        SELECT id, AcctSeed__Type__c
        FROM AcctSeed__Ledger__c
        WHERE AcctSeed__Type__c = 'Transactional'
        LIMIT 1
      ];
      salesOrder.AcctSeedERP__Ledger__c = led.id;
    }
    Id isOnlineOrderRT = LGND_Utilities.recordTypeIdFromName('AcctSeedERP__Sales_Order__c', 'Online Orders');
    salesOrder.RecordTypeId = isOnlineOrderRT;
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    Id retailPbId = settings.Default_Retail_Pricebook__c;
    salesOrder.Pricebook__c = retailPbId;
    upsert salesOrder;
    createSalesOrderLineItem(this.order_wrapper.items, salesOrder, acc, salesOrder.AcctSeedERP__Sales_Order_Line__r);
    return salesOrder;
  }
  public EcwidOrderWrapper.cls_items addSalesLineItemForShippingCharge() {
    EcwidOrderWrapper.cls_items ShippingChargeItem = new EcwidOrderWrapper.cls_items();
    ShippingChargeItem.sku = EcwidRestUtils.setting.Freight_Purolator_SKU__c;
    ShippingChargeItem.price = this.order_wrapper.shippingOption != null
      ? this.order_wrapper.shippingOption.shippingRate
      : '0';
    ShippingChargeItem.quantity = '1';
    return ShippingChargeItem;
  }

  /*
   * This function create / update the Sales Order Line item
   */
  public void createSalesOrderLineItem(
    List<EcwidOrderWrapper.cls_items> lstSalesOrderLineItemFromEcwid,
    AcctSeedERP__Sales_Order__c salesOrder,
    Account account,
    List<AcctSeedERP__Sales_Order_Line__c> lstExistingSalesOrderLine
  ) {
    Map<Id, AcctSeedERP__Sales_Order_Line__c> mapExistingLineItem = new Map<Id, AcctSeedERP__Sales_Order_Line__c>();
    List<AcctSeedERP__Sales_Order_Line__c> lstOrderLineItemToSave = new List<AcctSeedERP__Sales_Order_Line__c>();
    Map<String, Product2> mapProduct = new Map<String, Product2>();
    Map<String, EcwidOrderWrapper.cls_items> mapEcwidProductItem = new Map<String, EcwidOrderWrapper.cls_items>();
    List<String> lstProductSku = new List<String>();
    Boolean isCreated;
    try {
      //map for the existing line items
      if (!lstExistingSalesOrderLine.isEmpty()) {
        for (AcctSeedERP__Sales_Order_Line__c existingLineItem : lstExistingSalesOrderLine) {
          mapExistingLineItem.put(existingLineItem.AcctSeedERP__Product__c, existingLineItem);
        }
      }
      for (EcwidOrderWrapper.cls_items item : lstSalesOrderLineItemFromEcwid) {
        lstProductSku.add(item.sku);
        mapEcwidProductItem.put(item.sku, item);
      }

      //add a shipping charge line item, this is not an inventory product
      EcwidOrderWrapper.cls_items ShippingChargeItem = addSalesLineItemForShippingCharge();
      lstProductSku.add(ShippingChargeItem.sku);
      mapEcwidProductItem.put(ShippingChargeItem.sku, ShippingChargeItem);

      if (!lstProductSku.isEmpty()) {
        List<Product2> lstProduct = getProductData(lstProductSku);
        Map<Id, Decimal> mapProductPrice = getPriceFromPriceBook(lstProduct);

        for (Product2 product : lstProduct) {
          isCreated = false;
          if (mapEcwidProductItem.containsKey(product.Unique_Product_Code__c)) {
            EcwidOrderWrapper.cls_items itemFromEcwid = mapEcwidProductItem.get(product.Unique_Product_Code__c);
            AcctSeedERP__Sales_Order_Line__c OrderLineItem;

            if (mapExistingLineItem != null && mapExistingLineItem.containsKey(product.Id)) {
              //exising line item
              OrderLineItem = mapExistingLineItem.get(product.Id);
              mapExistingLineItem.remove(product.Id);
            } else {
              //new line item
              OrderLineItem = new AcctSeedERP__Sales_Order_Line__c();
              isCreated = true;
            }
            OrderLineItem.AcctSeedERP__Product__c = product.Id;
            OrderLineItem.AcctSeedERP__Quantity_Ordered__c = Integer.valueOf(itemFromEcwid.quantity);
            OrderLineItem.AcctSeedERP__Unit_Price__c = Double.valueOf(itemFromEcwid.price);
            OrderLineItem.AcctSeedERP__Comment__c = '';
            OrderLineItem.Review_Price__c = false;
            OrderLineItem.GMBLASERP__Price_Override__c = true;
            OrderLineItem.AcctSeedERP__GL_Account_Variable_2__c = salesOrder.GL_Account_Variable_2__c;
            OrderLineItem.AcctSeedERP__GL_Account_Variable_1__c = salesOrder.GL_Account_Variable_1__c;
            OrderLineItem.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;

            if (
              !mapProductPrice.isEmpty() &&
              mapProductPrice.containsKey(product.Id) &&
              mapProductPrice.get(Product.Id) <> OrderLineItem.AcctSeedERP__Unit_Price__c
            ) {
              OrderLineItem.Review_Price__c = true;
            }
            if (isCreated) {
              OrderLineItem.AcctSeedERP__Sales_Order__c = salesOrder.id;
            }
            lstOrderLineItemToSave.add(OrderLineItem);
          }
        }
      }

      List<AcctSeedERP__Sales_Order_Line__c> lstOrderLineItemTobeRemoved = new List<AcctSeedERP__Sales_Order_Line__c>();
      if (!mapExistingLineItem.isEmpty()) {
        lstOrderLineItemTobeRemoved = mapExistingLineItem.Values();
      }

      if (!lstOrderLineItemToSave.isEmpty()) {
        upsert lstOrderLineItemToSave;
      }
      //If any ilne item deleted from the sales Order
      if (!lstOrderLineItemTobeRemoved.isEmpty()) {
        delete lstOrderLineItemTobeRemoved;
      }
    } catch (Exception e) {
      System.debug('Exception in updateAccount: ' + e.getMessage());
    }
  }

  public List<Product2> getProductData(List<String> lstProductSku) {
    List<Product2> lstProduct = [
      SELECT Id, Unique_Product_Code__c
      FROM Product2
      WHERE Unique_Product_Code__c IN :lstProductSku
    ];
    return lstProduct;
  }

  public Map<Id, Decimal> getPriceFromPriceBook(List<Product2> lstProduct) {
    List<PricebookEntry> lstPriceFromPriceBook = [
      SELECT UnitPrice, Product2Id
      FROM PricebookEntry
      WHERE Product2Id IN :lstProduct AND Pricebook2Id = '01si0000000KoRPAA0'
    ];
    Map<Id, Decimal> mapProductPrice = new Map<Id, Decimal>();
    for (PricebookEntry price : lstPriceFromPriceBook) {
      mapProductPrice.put(price.Product2Id, price.UnitPrice);
    }
    return mapProductPrice;
  }
}
