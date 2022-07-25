public without sharing class SalesOrderLine_Service {
  public static Set<Id> productId_Set = new Set<Id>();
  public static Map<Id, Product2> mapProduct = new Map<Id, Product2>();

  public static void setTaxes(List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_list) {
    for (AcctSeedERP__Sales_Order_Line__c sol : salesOrderLine_list) {
      productId_Set.add(sol.AcctSeedERP__Product__c);
    }
    if (!productId_Set.isEmpty()) {
      getProductDetails(productId_Set);
    }
    for (AcctSeedERP__Sales_Order_Line__c sol : salesOrderLine_list) {
      if (mapProduct.containsKey(sol.AcctSeedERP__Product__c)) {
        Product2 product = mapProduct.get(sol.AcctSeedERP__Product__c);
        sol.Taxable_Federal__c = product.Taxable__c;
        sol.Taxable_Provincial__c = product.Taxable__c;
        sol.Taxable_Retail__c = false;
      }
    }
  }
  private static void getProductDetails(Set<Id> productId_Set) {
    for (Product2 p : [
      SELECT Id, GMBLASERP__Lot_Tracked__c, AcctSeedERP__Serialized__c, RecordType.Name, Taxable__c
      FROM Product2
      WHERE Id IN :productId_Set
    ]) {
      mapProduct.put(p.Id, p);
    }
  }
  public static void updateSalesTax(set<Id> salesOrder_Id_Set) {
    Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
    List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_List = new List<AcctSeedERP__Sales_Order_Line__c>();
    List<AcctSeedERP__Sales_Order_Line__c> salesOrderLine_ToBe_Deleted_List = new List<AcctSeedERP__Sales_Order_Line__c>();
    List<AcctSeedERP__Sales_Order__c> listSO = SalesOrder_Selector.byIdsIncludingSOL(salesOrder_Id_Set);
    for (AcctSeedERP__Sales_Order__c salesOrder : listSO) {
      AcctSeedERP__Sales_Order_Line__c taxLineFederal;
      AcctSeedERP__Sales_Order_Line__c taxLineProvincial;
      AcctSeedERP__Sales_Order_Line__c taxLineRetail;
      AcctSeedERP__Sales_Order_Line__c taxLineHarmonized;
      AcctSeedERP__Sales_Order_Line__c lineProductPrecisionFix;

      Decimal taxRateFederal = (salesOrder.Tax_Rate_Federal__c == null ? 0 : salesOrder.Tax_Rate_Federal__c) / 100;
      Decimal taxRateProvincial =
        (salesOrder.Tax_Rate_Provincial__c == null ? 0 : salesOrder.Tax_Rate_Provincial__c) / 100;
      Decimal taxRateRetail = (salesOrder.Tax_Rate_Retail__c == null ? 0 : salesOrder.Tax_Rate_Retail__c) / 100;
      Decimal taxRateHarmonized = (salesOrder.Tax_is_Harmonized__c == true ? (taxRateFederal + taxRateProvincial) : 0);
      if (salesOrder.Tax_is_Harmonized__c) {
        taxRateFederal = 0;
        taxRateProvincial = 0;
      }

      Decimal taxableAmountFederal = 0;
      Decimal taxableAmountProvincial = 0;
      Decimal taxableAmountRetail = 0;
      Decimal taxableAmountHarmonized = 0;
      Decimal totalLineAmount = 0;
      for (AcctSeedERP__Sales_Order_Line__c bl : salesOrder.AcctSeedERP__Sales_Order_Line__r) {
        if (bl.AcctSeedERP__Product__c == idProductSalesTaxHarmonized) {
          if (taxRateHarmonized == 0 || taxLineHarmonized != null)
            salesOrderLine_ToBe_Deleted_List.add(bl);
          else
            taxLineHarmonized = bl;
          continue;
        }
        totalLineAmount += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);

        if (bl.Taxable_Federal__c)
          taxableAmountFederal += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
        if (bl.Taxable_Provincial__c)
          taxableAmountProvincial += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
        if (bl.Taxable_Provincial__c || bl.Taxable_Federal__c)
          taxableAmountHarmonized += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
        if (bl.Taxable_Retail__c)
          taxableAmountRetail += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);

        if (bl.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c) {
          bl.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
          salesOrderLine_List.add(bl);
        }
      }

      if (taxableAmountFederal == 0) {
        if (taxLineFederal != null)
          salesOrderLine_ToBe_Deleted_List.add(taxLineFederal);
      } else if (taxRateFederal != 0) {
        taxLineFederal = checkAndProcessSOL(
          taxRateFederal,
          taxLineFederal,
          salesOrder,
          taxableAmountFederal,
          'Federal'
        );
        taxLineFederal.Taxable_Provincial__c = false;
        totalLineAmount += (taxRateFederal.setScale(5) * taxableAmountFederal.setScale(2)).setScale(2);
        salesOrderLine_List.add(taxLineFederal);
      }

      if (taxableAmountProvincial == 0) {
        if (taxLineProvincial != null)
          salesOrderLine_ToBe_Deleted_List.add(taxLineProvincial);
      } else if (taxRateProvincial != 0) {
        taxLineProvincial = checkAndProcessSOL(
          taxRateProvincial,
          taxLineProvincial,
          salesOrder,
          taxableAmountProvincial,
          'Provincial'
        );
        taxLineProvincial.Taxable_Provincial__c = false;
        totalLineAmount += (taxRateProvincial.setScale(5) * taxableAmountProvincial.setScale(2)).setScale(2);
        salesOrderLine_List.add(taxLineProvincial);
      }

      if (taxableAmountRetail == 0) {
        if (taxLineRetail != null)
          salesOrderLine_ToBe_Deleted_List.add(taxLineRetail);
      } else if (taxRateRetail != 0) {
        taxLineRetail = checkAndProcessSOL(taxRateRetail, taxLineRetail, salesOrder, taxableAmountRetail, 'Retail');
        taxLineRetail.Taxable_Retail__c = false;
        totalLineAmount += (taxRateRetail.setScale(5) * taxableAmountRetail.setScale(2)).setScale(2);
        salesOrderLine_List.add(taxLineRetail);
      }
      if (taxableAmountHarmonized == 0) {
        if (taxLineHarmonized != null)
          salesOrderLine_ToBe_Deleted_List.add(taxLineHarmonized);
      } else if (taxRateHarmonized != 0) {
        taxLineHarmonized = checkAndProcessSOL(
          taxRateHarmonized,
          taxLineHarmonized,
          salesOrder,
          taxableAmountHarmonized,
          'Harmonized'
        );
        taxLineHarmonized.Taxable_Provincial__c = false;
        totalLineAmount += (taxRateHarmonized.setScale(5) * taxableAmountHarmonized.setScale(2)).setScale(2);
        salesOrderLine_List.add(taxLineHarmonized);
      }

      Decimal actualValue = totalLineAmount.setScale(6);
      Decimal acctSeedValue = totalLineAmount.setScale(2, System.RoundingMode.HALF_UP);
      Decimal currentPrecision = (acctSeedValue - actualValue).setScale(6);
      if (currentPrecision != 0) {
        lineProductPrecisionFix = checkPrecision(currentPrecision, lineProductPrecisionFix, salesOrder);
        salesOrderLine_List.add(lineProductPrecisionFix);
      } else {
        if (lineProductPrecisionFix != null)
          salesOrderLine_ToBe_Deleted_List.add(lineProductPrecisionFix);
      }
    }
    if (!salesOrderLine_ToBe_Deleted_List.isEmpty() || !salesOrderLine_List.isEmpty()) {
      TriggerBase.bypass('AcctSeedERP__Sales_Order__c');
      TriggerBase.bypass('AcctSeedERP__Sales_Order_Line__c');
      if (!salesOrderLine_ToBe_Deleted_List.isEmpty())
        delete salesOrderLine_ToBe_Deleted_List;
      if (!salesOrderLine_List.isEmpty())
        upsert salesOrderLine_List;
      TriggerBase.clearAllBypasses();
    }
  }

  /// Product Kitting
  public static void insertKitParts(set<Id> setIdsolKit) {
    list<AcctSeedERP__Sales_Order_Line__c> listSOLKit = new List<AcctSeedERP__Sales_Order_Line__c>();
    map<Id, Product2> mapKit = new Map<Id, Product2>();
    list<AcctSeedERP__Sales_Order_Line__c> listSOLComp = new List<AcctSeedERP__Sales_Order_Line__c>();

    for (AcctSeedERP__Sales_Order_Line__c solKit : [
      SELECT
        Id,
        AcctSeedERP__Sales_Order__c,
        AcctSeedERP__Sales_Order__r.GL_Account_Variable_1__c,
        AcctSeedERP__Sales_Order__r.GL_Account_Variable_2__c,
        AcctSeedERP__Sales_Order__r.GL_Account_Variable_3__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Project__c,
        AcctSeedERP__Project_Task__c,
        AcctSeedERP__Quantity_Ordered__c,
        Part_Quantity_Specified_Multiplier__c
      FROM AcctSeedERP__Sales_Order_Line__c
      WHERE
        Id IN :setIdsolKit
        AND AcctSeedERP__Product__r.Composite_Type__c = 'Kit'
        AND AcctSeedERP__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle
    ]) {
      if (!mapKit.containsKey(solKit.AcctSeedERP__Product__c))
        mapKit.put(solKit.AcctSeedERP__Product__c, null);

      listSOLKit.add(solKit);
    }
    for (Product2 kit : [
      SELECT
        Id,
        (
          SELECT Id, AcctSeed__Product__c, AcctSeed__Product_Part__c, AcctSeed__Quantity__c
          FROM AcctSeed__Product_Parts__r
          WHERE AcctSeed__Product__r.RecordTypeId != :LGND_Constants.productRtId_Bundle
        )
      FROM Product2
      WHERE Id IN :mapKit.keySet() AND RecordTypeId != :LGND_Constants.productRtId_Bundle
    ]) {
      mapKit.put(kit.Id, kit);
    }

    for (AcctSeedERP__Sales_Order_Line__c solKit : listSOLKit) {
      Product2 kit = mapKit.get(solKit.AcctSeedERP__Product__c);

      for (AcctSeed__Product_Part__c comp : kit.AcctSeed__Product_Parts__r) {
        listSOLComp.add(
          new AcctSeedERP__Sales_Order_Line__c(
            AcctSeedERP__Product__c = comp.AcctSeed__Product_Part__c,
            Sales_Order_Line__c = solKit.Id,
            GMBLASERP__Price_Override__c = true,
            AcctSeedERP__Unit_Price__c = 0,
            AcctSeedERP__Sales_Order__c = solKit.AcctSeedERP__Sales_Order__c,
            AcctSeedERP__Project__c = solKit.AcctSeedERP__Project__c,
            AcctSeedERP__Project_Task__c = solKit.AcctSeedERP__Project_Task__c,
            AcctSeedERP__GL_Account_Variable_1__c = solKit.AcctSeedERP__Sales_Order__r.GL_Account_Variable_1__c,
            AcctSeedERP__GL_Account_Variable_2__c = solKit.AcctSeedERP__Sales_Order__r.GL_Account_Variable_2__c,
            Part_Quantity_Specified_Multiplier__c = (comp.AcctSeed__Quantity__c == null
              ? 0
              : comp.AcctSeed__Quantity__c),
            AcctSeedERP__Quantity_Ordered__c = (comp.AcctSeed__Quantity__c == null ? 0 : comp.AcctSeed__Quantity__c) *
              (solKit.AcctSeedERP__Quantity_Ordered__c == null ? 0 : solKit.AcctSeedERP__Quantity_Ordered__c)
          )
        );
      }
    }

    if (!listSOLComp.isEmpty()) {
      MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_AI');
      MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_AU');
      insert listSOLComp;
      MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_AI');
      MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_AU');
    }
  }

  public static void cascadeDeleteKitMaterial(set<Id> setIdMatl) {
    setIdMatl.remove(null);
    if (!setIdMatl.isEmpty()) {
      MetadataTriggerHandler.bypass('TA_SalesOrderLine_KIT_BD');
      delete [
        SELECT Id
        FROM AcctSeedERP__Sales_Order_Line__c
        WHERE Sales_Order_Line__c IN :setIdMatl AND Id NOT IN :setIdMatl
      ];
      MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_KIT_BD');
    }
  }

  public static void updateMaterialSpec(set<Id> setIdsolKit) {
    setIdsolKit.remove(null);
    if (setIdsolKit.isEmpty())
      return;

    list<AcctSeedERP__Sales_Order_Line__c> listSOL = new List<AcctSeedERP__Sales_Order_Line__c>();

    for (AcctSeedERP__Sales_Order_Line__c matl : [
      SELECT
        Id,
        Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c,
        AcctSeedERP__Quantity_Ordered__c,
        Part_Quantity_Specified_Multiplier__c
      FROM AcctSeedERP__Sales_Order_Line__c
      WHERE Sales_Order_Line__c IN :setIdsolKit
    ]) {
      Decimal qtySpecified =
        (matl.Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c == null
          ? 0
          : matl.Sales_Order_Line__r.AcctSeedERP__Quantity_Ordered__c) *
        (matl.Part_Quantity_Specified_Multiplier__c == null ? 0 : matl.Part_Quantity_Specified_Multiplier__c);
      qtySpecified = qtySpecified.setScale(6);

      if (
        matl.AcctSeedERP__Quantity_Ordered__c == null ||
        matl.AcctSeedERP__Quantity_Ordered__c.setScale(6) != qtySpecified
      ) {
        matl.AcctSeedERP__Quantity_Ordered__c = qtySpecified;
        listSOL.add(matl);
      }
    }

    if (!listSOL.isEmpty()) {
      MetadataTriggerHandler.bypass('TA_SalesOrderLine_BU');
      update listSOL;
      MetadataTriggerHandler.clearBypass('TA_SalesOrderLine_BU');
    }
  }

  private static AcctSeedERP__Sales_Order_Line__c checkAndProcessSOL(
    Decimal taxRate,
    AcctSeedERP__Sales_Order_Line__c taxLine,
    AcctSeedERP__Sales_Order__c salesOrder,
    Decimal taxableAmount,
    String type
  ) {
    Id idProductSalesTaxFederal = gcConstants.idProductSalesTaxFederal;
    Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
    Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
    Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
    Id idProductSalesTax;
    if (type == 'Retail') {
      idProductSalesTax = idProductSalesTaxRetail;
    } else if (type == 'Federal') {
      idProductSalesTax = idProductSalesTaxFederal;
    } else if (type == 'Provincial') {
      idProductSalesTax = idProductSalesTaxProvincial;
    } else if (type == 'Harmonized') {
      idProductSalesTax = idProductSalesTaxHarmonized;
    }

    if (taxLine != null) {
      if (
        taxLine.AcctSeedERP__Quantity_Ordered__c != taxRate.setScale(5) ||
        taxLine.AcctSeedERP__Unit_Price__c != taxableAmount.setScale(2) ||
        taxLine.AcctSeedERP__GL_Account_Variable_3__c != salesOrder.GL_Account_Variable_3__c ||
        taxLine.AcctSeedERP__GL_Account_Variable_3__c == null ||
        taxLine.Taxable_Retail__c == true
      ) {
        taxLine.AcctSeedERP__Quantity_Ordered__c = taxRate.setScale(5);
        taxLine.AcctSeedERP__Unit_Price__c = taxableAmount.setScale(2);
        if (taxLine.AcctSeedERP__GL_Account_Variable_3__c == null)
          taxLine.AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c;
        taxLine.Taxable_Retail__c = false;
      }
    } else {
      taxLine = new AcctSeedERP__Sales_Order_Line__c(
        AcctSeedERP__Sales_Order__c = salesOrder.Id,
        AcctSeedERP__Product__c = idProductSalesTax,
        AcctSeedERP__Quantity_Ordered__c = taxRate.setScale(5),
        AcctSeedERP__Unit_Price__c = taxableAmount.setScale(2),
        AcctSeedERP__GL_Account_Variable_3__c = salesOrder.GL_Account_Variable_3__c,
        Taxable_Retail__c = false
      );
    }

    return taxLine;
  }

  private static AcctSeedERP__Sales_Order_Line__c checkPrecision(
    Decimal currentPrecision,
    AcctSeedERP__Sales_Order_Line__c lineProductPrecisionFix,
    AcctSeedERP__Sales_Order__c salesOrder
  ) {
    Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
    Id idGlv3Others = gcConstants.idGlv3Others;
    if (lineProductPrecisionFix != null) {
      lineProductPrecisionFix.AcctSeedERP__Quantity_Ordered__c = 1;
      lineProductPrecisionFix.AcctSeedERP__Unit_Price__c = currentPrecision;
      lineProductPrecisionFix.Taxable_Federal__c = false;
      lineProductPrecisionFix.Taxable_Provincial__c = false;
      lineProductPrecisionFix.Taxable_Retail__c = false;
    } else {
      lineProductPrecisionFix = new AcctSeedERP__Sales_Order_Line__c(
        AcctSeedERP__Sales_Order__c = salesOrder.Id,
        AcctSeedERP__GL_Account_Variable_3__c = idGlv3Others,
        AcctSeedERP__Product__c = idProductPrecisionFix,
        AcctSeedERP__Quantity_Ordered__c = 1,
        AcctSeedERP__Unit_Price__c = currentPrecision,
        Taxable_Federal__c = false,
        Taxable_Provincial__c = false,
        Taxable_Retail__c = false
      );
    }

    return lineProductPrecisionFix;
  }
}
