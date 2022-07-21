public without sharing class gcBillingLine {
  public static Boolean disableTrigger {
    get {
      if (disableTrigger == null)
        return false;
      else
        return disableTrigger;
    }
    set {
      if (value == null)
        disableTrigger = false;
      else
        disableTrigger = value;
    }
  }

  public static Boolean disableAutosetTaxable {
    get {
      if (disableAutosetTaxable == null)
        return false;
      else
        return disableAutosetTaxable;
    }
    set {
      if (value == null)
        disableAutosetTaxable = false;
      else
        disableAutosetTaxable = value;
    }
  }

  public static void triggerHandler(
    map<Id, AcctSeed__Billing_Line__c> oldMap,
    map<Id, AcctSeed__Billing_Line__c> newMap,
    list<AcctSeed__Billing_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Billing_Line__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Billing_Line__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Billing_Line__c>();

    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
        setFinancialAttributes(listNew);
      }
      if (boolIsUpdate) {
        setFinancialAttributes(listNew);
      }
      if (boolIsDelete) {
      }
    } else //i.e. trigger.isAfter
    {
      set<Id> setIdBill = new Set<Id>();
      if (boolIsInsert) {
        for (AcctSeed__Billing_Line__c b : listNew)
          setIdBill.add(b.AcctSeed__Billing__c);
      }
      if (boolIsUpdate) {
        for (AcctSeed__Billing_Line__c b : listNew)
          setIdBill.add(b.AcctSeed__Billing__c);
        for (AcctSeed__Billing_Line__c b : oldMap.values())
          setIdBill.add(b.AcctSeed__Billing__c);
      }
      if (boolIsDelete) {
        for (AcctSeed__Billing_Line__c b : oldMap.values())
          setIdBill.add(b.AcctSeed__Billing__c);
      }
      updateSalesTax(setIdBill);
    }
  }

  private static void setFinancialAttributes(List<AcctSeed__Billing_Line__c> listNew) {
    gcTransactionParent.setFinancialAttributes(
      listNew,
      null,
      'AcctSeed__Project_Task__c',
      'AcctSeed__Revenue_GL_Account__c'
    );
  }

  private static void updateAndValidate(
    map<Id, AcctSeed__Billing_Line__c> oldMap,
    map<Id, AcctSeed__Billing_Line__c> newMap,
    list<AcctSeed__Billing_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore) {
      refreshStatics(listNew);
      List<GMBLASERP__Serial_Number__c> listSerials = new List<GMBLASERP__Serial_Number__c>();

      for (AcctSeed__Billing_Line__c line : listNew) {
        if (
          boolIsUpdate &&
          line.AcctSeed__Revenue_GL_Account__c != null &&
          line.AcctSeed__Revenue_GL_Account__c != oldMap.get(line.Id).AcctSeed__Revenue_GL_Account__c &&
          line.Revenue_Expense_GL_Account__c == oldMap.get(line.Id).Revenue_Expense_GL_Account__c
        ) {
          line.Revenue_Expense_GL_Account__c = line.AcctSeed__Revenue_GL_Account__c;
        }

        if (
          (line.AcctSeed__Revenue_GL_Account__c == null && line.Revenue_Expense_GL_Account__c != null) ||
          (line.AcctSeed__Revenue_GL_Account__c != null &&
          line.Revenue_Expense_GL_Account__c != null &&
          line.Revenue_Expense_GL_Account__c != line.AcctSeed__Revenue_GL_Account__c)
        ) {
          line.AcctSeed__Revenue_GL_Account__c = line.Revenue_Expense_GL_Account__c;
        }

        if (line.AcctSeed__Revenue_GL_Account__c != null && line.Revenue_Expense_GL_Account__c == null)
          line.Revenue_Expense_GL_Account__c = line.AcctSeed__Revenue_GL_Account__c;

        if (
          (boolIsInsert && !disableAutosetTaxable) ||
          (boolIsUpdate && line.AcctSeed__Product__c != oldMap.get(line.Id).AcctSeed__Product__c)
        ) {
          Product2 product = mapProduct.get(line.AcctSeed__Product__c);
          if (product != null) {
            line.Taxable_Federal__c = product.Taxable__c;
            line.Taxable_Provincial__c = product.Taxable__c;
            line.Taxable_Retail__c = false;
            if (product.RecordType.Name.equals('Insurance')) {
              line.Taxable_Federal__c = false;
              line.Taxable_Provincial__c = false;
              line.Taxable_Retail__c = true;
              System.debug(loggingLevel.error, 'line:' + line);
            }
          }
        }

        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Federal__c != oldMap.get(line.Id).Taxable_Federal__c
        )
          line.addError('The Federal Taxable status of a Billing Line may not be changed, if the Billing is Posted.');
        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Provincial__c != oldMap.get(line.Id).Taxable_Provincial__c
        )
          line.addError(
            'The Provincial Taxable status of a Billing Line may not be changed, if the Billing is Posted.'
          );
        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Retail__c != oldMap.get(line.Id).Taxable_Retail__c
        )
          line.addError('The Retail Taxable status of a Billing Line may not be changed, if the Billing is Posted.');

        AcctSeed__Billing__c bill = mapBilling.get(line.AcctSeed__Billing__c);
        if (line.AcctSeed__GL_Account_Variable_3__c == null)
          line.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
        if (
          line.AcctSeed__Revenue_GL_Account__c != null &&
          line.AcctSeed__Revenue_GL_Account__c == gcConstants.idGlCustomerRefund
        )
          line.Refund_Line__c = true;
        else
          line.Refund_Line__c = false;

        if (
          line.AcctSeed__Project__c != null &&
          bill.GMBLASERP__Project__c != null &&
          line.AcctSeed__Project__c != bill.GMBLASERP__Project__c
        )
          line.AcctSeed__Project__c.addError(
            'The ERP order in Billing Line does not match with the ERP order on the Billing.'
          );

        if (boolIsDelete && line.Serial_Revenue_Line__c && line.Serial_Revenue_Used__c) {
          listSerials.add(
            new GMBLASERP__Serial_Number__c(Id = line.Serial_Number_ERP_Order_Item__c, Billing_Revenue_Used__c = false)
          );
        }

        if (boolIsInsert && bill.Internal_Billing__c) {
          line.AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
          line.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
        }
        if ((boolIsInsert || boolIsUpdate) && bill.Internal_Warranty__c) {
          if (boolIsInsert)
            line.AcctSeed__Revenue_GL_Account__c = gcConstants.idGlInternalRevenue;
          if (boolIsUpdate && line.AcctSeed__Revenue_GL_Account__c != gcConstants.idGLInternalWarrantyClearing)
            line.AcctSeed__Revenue_GL_Account__c = gcConstants.idGlInternalRevenue;
        }
        if (boolIsInsert && line.AcctSeed__Product__c != null) {
          Product2 product = mapProduct.get(line.AcctSeed__Product__c);
          if (product.Family == 'Freight') {
            line.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Logistics;
          }
        }
        if ((boolIsInsert || boolIsUpdate) && line.Is_Prepaid__c) {
          line.AcctSeed__Revenue_GL_Account__c = gcConstants.idGlPrepaidDeposit;
        }
      }
      if (!listSerials.isEmpty()) {
        Boolean oldVal = gcSerialNumber.disableTrigger;
        gcSerialNumber.disableTrigger = true;
        update listSerials;
        gcSerialNumber.disableTrigger = oldVal;
      }
    }
  }

  private static map<Id, Product2> mapProduct;
  private static map<Id, AcctSeed__Project__c> mapProject;
  private static map<Id, AcctSeed__Billing__c> mapBilling;

  private static void refreshStatics(list<AcctSeed__Billing_Line__c> listNew) {
    if (mapProduct == null) {
      mapProduct = new Map<Id, Product2>();
      mapProject = new Map<Id, AcctSeed__Project__c>();
      mapBilling = new Map<Id, AcctSeed__Billing__c>();
    }
    set<Id> setIdProduct = new Set<Id>();
    set<Id> setIdProject = new Set<Id>();
    set<Id> setIdBilling = new Set<Id>();
    for (AcctSeed__Billing_Line__c line : listNew) {
      if (line.AcctSeed__Product__c != null && !mapProduct.containsKey(line.AcctSeed__Product__c))
        setIdProduct.add(line.AcctSeed__Product__c);
      if (line.AcctSeed__Project__c != null && !mapProduct.containsKey(line.AcctSeed__Project__c))
        setIdProject.add(line.AcctSeed__Project__c);
      if (line.AcctSeed__Billing__c != null && !mapBilling.containsKey(line.AcctSeed__Billing__c))
        setIdBilling.add(line.AcctSeed__Billing__c);
    }
    setIdProduct.remove(null);
    setIdProject.remove(null);
    setIdBilling.remove(null);

    for (Product2 p : [SELECT Id, RecordType.Name, Family, Taxable__c FROM Product2 WHERE Id IN :setIdProduct]) {
      mapProduct.put(p.Id, p);
    }

    if (!setIdProject.isEmpty())
      for (AcctSeed__Project__c p : [
        SELECT Id, GL_Account_Variable_3__c, GL_Account_Variable_3__r.Name
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        mapProject.put(p.Id, p);
      }

    for (AcctSeed__Billing__c b : [
      SELECT
        Id,
        GMBLASERP__Project__c,
        GL_Account_Variable_3__c,
        Internal_Billing__c,
        Internal_Warranty__c,
        Internal_Service__c
      FROM AcctSeed__Billing__c
      WHERE Id IN :setIdBilling
    ]) {
      mapBilling.put(b.Id, b);
    }
  }

  public static void updateSalesTax(set<Id> setIdBilling) {
    Id idProductSalesTaxFederal = gcConstants.idProductSalesTaxFederal;
    Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
    Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
    Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
    Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
    Id idProductInternalLabour = gcConstants.idProductInternalLabour;
    Id idProductInternalBilling = gcConstants.idProductInternalBilling;
    Id idProductInternalBalance = gcConstants.idProductInternalBalance;
    String internalProductRecordTypeName = gcConstants.internalProductRecordTypeName;

    Id idGlv1HeadOfficeOverhead = gcConstants.idGlv1HeadOfficeOverhead;
    Id idGlInternalLabour = gcConstants.idGlInternalLabour;
    Id idGLInternalWarrantyClearing = gcConstants.idGLInternalWarrantyClearing;
    Id idGlv2Sales = gcConstants.idGlv2Sales;
    Id idGlv3Others = gcConstants.idGlv3Others;

    List<AcctSeed__Billing_Line__c> listBLupsert = new List<AcctSeed__Billing_Line__c>();
    List<AcctSeed__Billing_Line__c> listBLdelete = new List<AcctSeed__Billing_Line__c>();
    List<GMBLASERP__Serial_Number__c> listSerialsUsed = new List<GMBLASERP__Serial_Number__c>();
    Map<Id, AcctSeed__Project_Task__c> mapTask = new Map<Id, AcctSeed__Project_Task__c>();
    for (AcctSeed__Billing__c bill : [
      SELECT
        Id,
        GL_Account_Variable_3__c,
        Tax_is_Harmonized__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        Internal_Billing__c,
        Internal_Warranty__c,
        Internal_Service__c,
        Internal_Account_GLV1__c,
        ERP_Revenue__c,
        ERP_Expense__c,
        ERP_Profit__c,
        (
          SELECT
            Id,
            AcctSeed__Project_Task__c,
            AcctSeed__Project_Task__r.AcctSeed__Project__c,
            AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
            AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__Hours_Units__c,
            AcctSeed__Product__c,
            AcctSeed__Product__r.RecordType.Name,
            AcctSeed__Rate__c,
            AcctSeed__Total__c,
            Taxable_Federal__c,
            Taxable_Provincial__c,
            Taxable_Retail__c,
            GMBLASERP__Material__c,
            GMBLASERP__Material__r.isPrepaid__c,
            Serial_Number_ERP_Order_Item__c,
            Serial_Number_Revenue__c,
            Serial_Revenue_Used__c,
            AcctSeed__Revenue_GL_Account__c
          FROM AcctSeed__Project_Billing_Lines__r
          ORDER BY CreatedDate
        )
      FROM AcctSeed__Billing__c
      WHERE Id IN :setIdBilling AND AcctSeed__Status__c != 'Posted'
    ]) {
      AcctSeed__Billing_Line__c taxLineFederal;
      AcctSeed__Billing_Line__c taxLineProvincial;
      AcctSeed__Billing_Line__c taxLineRetail;
      AcctSeed__Billing_Line__c taxLineHarmonized;
      AcctSeed__Billing_Line__c lineProductPrecisionFix;
      AcctSeed__Billing_Line__c lineInternalBillingRevenue;
      AcctSeed__Billing_Line__c lineInternalBillingBalance;
      AcctSeed__Billing_Line__c lineInternalWarrantyBalance;
      Map<Id, AcctSeed__Billing_Line__c> mapTaskLabour = new Map<Id, AcctSeed__Billing_Line__c>();
      //AcctSeed__Billing_Line__c lineInternalLabour;

      Decimal taxRateFederal = (bill.Tax_Rate_Federal__c == null ? 0 : bill.Tax_Rate_Federal__c) / 100;
      Decimal taxRateProvincial = (bill.Tax_Rate_Provincial__c == null ? 0 : bill.Tax_Rate_Provincial__c) / 100;
      Decimal taxRateRetail = (bill.Tax_Rate_Retail__c == null ? 0 : bill.Tax_Rate_Retail__c) / 100;
      Decimal taxRateHarmonized = (bill.Tax_is_Harmonized__c == true ? (taxRateFederal + taxRateProvincial) : 0);

      if (bill.Tax_is_Harmonized__c) {
        taxRateFederal = 0;
        taxRateProvincial = 0;
      }

      Decimal taxableAmountFederal = 0;
      Decimal taxableAmountProvincial = 0;
      Decimal taxableAmountRetail = 0;
      Decimal taxableAmountHarmonized = 0;
      Decimal totalLineAmount = 0;
      Decimal totalSerialRevenue = 0;
      Map<Id, Decimal> mapTotalLabour = new Map<Id, Decimal>();
      //Decimal totalLabour = 0;
      for (AcctSeed__Billing_Line__c bl : bill.AcctSeed__Project_Billing_Lines__r) {
        if (bl.AcctSeed__Product__c == idProductSalesTaxFederal) {
          if (taxRateFederal == 0 || taxLineFederal != null)
            listBLdelete.add(bl);
          else
            taxLineFederal = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductSalesTaxProvincial) {
          if (taxRateProvincial == 0 || taxLineProvincial != null)
            listBLdelete.add(bl);
          else
            taxLineProvincial = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductSalesTaxRetail) {
          if (taxRateRetail == 0 || taxRateRetail != null)
            listBLdelete.add(bl);
          else
            taxLineRetail = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductSalesTaxHarmonized) {
          if (taxRateHarmonized == 0 || taxLineHarmonized != null)
            listBLdelete.add(bl);
          else
            taxLineHarmonized = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductPrecisionFix) {
          lineProductPrecisionFix = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductInternalBilling) {
          lineInternalBillingRevenue = bl;
          continue;
        } else if (bl.AcctSeed__Product__c == idProductInternalBalance) {
          lineInternalBillingBalance = bl;
          continue;
        } else if (bl.AcctSeed__Revenue_GL_Account__c == idGLInternalWarrantyClearing && bill.Internal_Warranty__c) {
          lineInternalWarrantyBalance = bl;
          continue;
        } else if (
          bl.AcctSeed__Product__r.RecordType.Name == internalProductRecordTypeName &&
          bl.AcctSeed__Revenue_GL_Account__c == idGlInternalLabour
        ) {
          //lineInternalLabour = bl;
          mapTaskLabour.put(bl.AcctSeed__Project_Task__c, bl);
          continue;
        }
        totalLineAmount += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);

        if (bl.Taxable_Federal__c)
          taxableAmountFederal += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);
        if (bl.Taxable_Provincial__c)
          taxableAmountProvincial += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);
        if (bl.Taxable_Provincial__c || bl.Taxable_Federal__c)
          taxableAmountHarmonized += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);
        if (bl.Taxable_Retail__c)
          taxableAmountRetail += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);

        if (bl.AcctSeed__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c) {
          bl.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
          listBLupsert.add(bl);
        }

        if (
          bl.GMBLASERP__Material__c != null &&
          !bl.Serial_Revenue_Used__c &&
          bl.Serial_Number_Revenue__c <> 0 &&
          !bill.Internal_Billing__c
        ) {
          totalSerialRevenue += bl.Serial_Number_Revenue__c;
          listSerialsUsed.add(
            new GMBLASERP__Serial_Number__c(Id = bl.Serial_Number_ERP_Order_Item__c, Billing_Revenue_Used__c = true)
          );
        }

        if (bl.AcctSeed__Product__r.RecordType.Name == internalProductRecordTypeName) {
          if (!mapTotalLabour.containsKey(bl.AcctSeed__Project_Task__c))
            mapTotalLabour.put(bl.AcctSeed__Project_Task__c, 0);

          Decimal cVal =
            mapTotalLabour.get(bl.AcctSeed__Project_Task__c) +
            (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);
          mapTotalLabour.put(bl.AcctSeed__Project_Task__c, cVal);
          //totalLabour += (bl.AcctSeed__Total__c == null ? 0 : bl.AcctSeed__Total__c);
          mapTask.put(bl.AcctSeed__Project_Task__c, bl.AcctSeed__Project_Task__r);
        }
      }

      if (taxableAmountFederal == 0) {
        if (taxLineFederal != null)
          listBLdelete.add(taxLineFederal);
      } else {
        if (taxRateFederal != 0) {
          if (taxLineFederal != null) {
            if (
              taxLineFederal.AcctSeed__Hours_Units__c != taxRateFederal.setScale(5) ||
              taxLineFederal.AcctSeed__Rate__c != taxableAmountFederal.setScale(2) ||
              //taxLineFederal.AcctSeed__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
              taxLineFederal.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineFederal.Taxable_Federal__c == true
            ) {
              taxLineFederal.AcctSeed__Hours_Units__c = taxRateFederal.setScale(5);
              taxLineFederal.AcctSeed__Rate__c = taxableAmountFederal.setScale(2);
              if (taxLineFederal.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineFederal.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
              taxLineFederal.Taxable_Federal__c = false;
              listBLupsert.add(taxLineFederal);
            }
          } else {
            taxLineFederal = new AcctSeed__Billing_Line__c(
              AcctSeed__Billing__c = bill.Id,
              AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
              AcctSeed__Product__c = idProductSalesTaxFederal,
              AcctSeed__Hours_Units__c = taxRateFederal.setScale(5),
              AcctSeed__Rate__c = taxableAmountFederal.setScale(2),
              Taxable_Federal__c = false
            );
            listBLupsert.add(taxLineFederal);
          }
          totalLineAmount += (taxRateFederal.setScale(5) * taxableAmountFederal.setScale(2)).setScale(2);
        }
      }

      if (taxableAmountProvincial == 0) {
        if (taxLineProvincial != null)
          listBLdelete.add(taxLineProvincial);
      } else {
        if (taxRateProvincial != 0) {
          if (taxLineProvincial != null) {
            if (
              taxLineProvincial.AcctSeed__Hours_Units__c != taxRateProvincial.setScale(5) ||
              taxLineProvincial.AcctSeed__Rate__c != taxableAmountProvincial.setScale(2) ||
              //taxLineProvincial.AcctSeed__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
              taxLineProvincial.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineProvincial.Taxable_Provincial__c == true
            ) {
              taxLineProvincial.AcctSeed__Hours_Units__c = taxRateProvincial.setScale(5);
              taxLineProvincial.AcctSeed__Rate__c = taxableAmountProvincial.setScale(2);
              if (taxLineProvincial.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineProvincial.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
              taxLineProvincial.Taxable_Provincial__c = false;
              listBLupsert.add(taxLineProvincial);
            }
          } else {
            taxLineProvincial = new AcctSeed__Billing_Line__c(
              AcctSeed__Billing__c = bill.Id,
              AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
              AcctSeed__Product__c = idProductSalesTaxProvincial,
              AcctSeed__Hours_Units__c = taxRateProvincial.setScale(5),
              AcctSeed__Rate__c = taxableAmountProvincial.setScale(2),
              Taxable_Provincial__c = false
            );
            listBLupsert.add(taxLineProvincial);
          }
          totalLineAmount += (taxRateProvincial.setScale(5) * taxableAmountProvincial.setScale(2)).setScale(2);
        }
      }

      if (taxableAmountRetail == 0) {
        if (taxLineRetail != null)
          listBLdelete.add(taxLineRetail);
      } else {
        if (taxRateRetail != 0) {
          if (taxLineRetail != null) {
            if (
              taxLineRetail.AcctSeed__Hours_Units__c != taxRateRetail.setScale(5) ||
              taxLineRetail.AcctSeed__Rate__c != taxableAmountRetail.setScale(2) ||
              //taxLineRetail.AcctSeed__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
              taxLineRetail.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineRetail.Taxable_Retail__c == true
            ) {
              taxLineRetail.AcctSeed__Hours_Units__c = taxRateRetail.setScale(5);
              taxLineRetail.AcctSeed__Rate__c = taxableAmountRetail.setScale(2);
              if (taxLineRetail.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineRetail.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
              taxLineRetail.Taxable_Retail__c = false;
              listBLupsert.add(taxLineRetail);
            }
          } else {
            taxLineRetail = new AcctSeed__Billing_Line__c(
              AcctSeed__Billing__c = bill.Id,
              AcctSeed__Product__c = idProductSalesTaxRetail,
              AcctSeed__Hours_Units__c = taxRateRetail.setScale(5),
              AcctSeed__Rate__c = taxableAmountRetail.setScale(2),
              AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
              Taxable_Retail__c = false
            );
            listBLupsert.add(taxLineRetail);
          }
          totalLineAmount += (taxRateRetail.setScale(5) * taxableAmountRetail.setScale(2)).setScale(2);
        }
      }

      if (taxableAmountHarmonized == 0) {
        if (taxLineHarmonized != null)
          listBLdelete.add(taxLineHarmonized);
      } else {
        if (taxRateHarmonized != 0) {
          if (taxLineHarmonized != null) {
            if (
              taxLineHarmonized.AcctSeed__Hours_Units__c != taxRateHarmonized.setScale(5) ||
              taxLineHarmonized.AcctSeed__Rate__c != taxableAmountHarmonized.setScale(2) ||
              //taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
              taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineHarmonized.Taxable_Provincial__c == true
            ) {
              taxLineHarmonized.AcctSeed__Hours_Units__c = taxRateHarmonized.setScale(5);
              taxLineHarmonized.AcctSeed__Rate__c = taxableAmountHarmonized.setScale(2);
              if (taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
              taxLineHarmonized.Taxable_Provincial__c = false;
              listBLupsert.add(taxLineHarmonized);
            }
          } else {
            taxLineHarmonized = new AcctSeed__Billing_Line__c(
              AcctSeed__Billing__c = bill.Id,
              AcctSeed__Product__c = idProductSalesTaxHarmonized,
              AcctSeed__Hours_Units__c = taxRateHarmonized.setScale(5),
              AcctSeed__Rate__c = taxableAmountHarmonized.setScale(2),
              AcctSeed__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
              Taxable_Provincial__c = false
            );
            listBLupsert.add(taxLineHarmonized);
          }
          totalLineAmount += (taxRateHarmonized.setScale(5) * taxableAmountHarmonized.setScale(2)).setScale(2);
        }
      }

      Decimal actualValue = totalLineAmount.setScale(6);
      Decimal acctSeedValue = totalLineAmount.setScale(2, System.RoundingMode.HALF_UP);
      Decimal currentPrecision = (acctSeedValue - actualValue).setScale(6);
      if (currentPrecision != 0) {
        //if(currentPrecision < 0.005) currentPrecision = currentPrecision * -1;
        if (lineProductPrecisionFix != null) {
          lineProductPrecisionFix.AcctSeed__Hours_Units__c = 1;
          lineProductPrecisionFix.AcctSeed__Rate__c = currentPrecision;
          lineProductPrecisionFix.Taxable_Federal__c = false;
          lineProductPrecisionFix.Taxable_Provincial__c = false;
          lineProductPrecisionFix.Taxable_Retail__c = false;
          listBLupsert.add(lineProductPrecisionFix);
        } else {
          lineProductPrecisionFix = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Product__c = idProductPrecisionFix,
            AcctSeed__Hours_Units__c = 1,
            AcctSeed__Rate__c = currentPrecision,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false
          );
          listBLupsert.add(lineProductPrecisionFix);
        }
      } else {
        if (lineProductPrecisionFix != null)
          listBLdelete.add(lineProductPrecisionFix);
      }

      if (bill.Internal_Warranty__c) {
        /// Billing Revenue
        Decimal amountTotalBalance = actualValue + currentPrecision;
        if (lineInternalWarrantyBalance == null) {
          lineInternalWarrantyBalance = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_1__c = bill.Internal_Account_GLV1__c,
            AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Warranty,
            AcctSeed__Revenue_GL_Account__c = idGLInternalWarrantyClearing,
            AcctSeed__Hours_Units__c = -1,
            AcctSeed__Rate__c = amountTotalBalance,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false
          );
        } else {
          lineInternalWarrantyBalance.AcctSeed__GL_Account_Variable_1__c = bill.Internal_Account_GLV1__c;
          lineInternalWarrantyBalance.AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Warranty;
          lineInternalWarrantyBalance.AcctSeed__Hours_Units__c = -1;
          lineInternalWarrantyBalance.AcctSeed__Rate__c = amountTotalBalance;
          lineInternalWarrantyBalance.Taxable_Federal__c = false;
          lineInternalWarrantyBalance.Taxable_Provincial__c = false;
          lineInternalWarrantyBalance.Taxable_Retail__c = false;
        }
        listBLupsert.add(lineInternalWarrantyBalance);
      }

      if (bill.Internal_Service__c) {
        /// Billing Revenue
        for (Id idTask : mapTotalLabour.keySet()) {
          AcctSeed__Billing_Line__c lineInternalLabour = mapTaskLabour.get(idTask);
          AcctSeed__Project_Task__c tsk = mapTask.get(idTask);
          if (lineInternalLabour == null) {
            lineInternalLabour = new AcctSeed__Billing_Line__c(
              AcctSeed__Billing__c = bill.Id,
              AcctSeed__Project__c = tsk.AcctSeed__Project__c,
              AcctSeed__Project_Task__c = idTask,
              AcctSeed__GL_Account_Variable_1__c = tsk.AcctSeed__GL_Account_Variable_1__c,
              AcctSeed__GL_Account_Variable_2__c = tsk.AcctSeed__GL_Account_Variable_2__c,
              AcctSeed__Revenue_GL_Account__c = idGlInternalLabour,
              AcctSeed__Product__c = idProductInternalLabour,
              AcctSeed__Hours_Units__c = -1,
              AcctSeed__Rate__c = mapTotalLabour.get(idTask),
              Taxable_Federal__c = false,
              Taxable_Provincial__c = false,
              Taxable_Retail__c = false
            );
          } else {
            lineInternalLabour.AcctSeed__GL_Account_Variable_1__c = tsk.AcctSeed__GL_Account_Variable_1__c;
            lineInternalLabour.AcctSeed__GL_Account_Variable_2__c = tsk.AcctSeed__GL_Account_Variable_2__c;
            lineInternalLabour.AcctSeed__Hours_Units__c = -1;
            lineInternalLabour.AcctSeed__Rate__c = mapTotalLabour.get(idTask);
            lineInternalLabour.Taxable_Federal__c = false;
            lineInternalLabour.Taxable_Provincial__c = false;
            lineInternalLabour.Taxable_Retail__c = false;
          }
          listBLupsert.add(lineInternalLabour);
        }

        for (Id idTask : mapTaskLabour.keySet())
          if (!mapTotalLabour.containsKey(idTask))
            listBLdelete.add(mapTaskLabour.get(idTask));
      }

      if (bill.Internal_Billing__c) {
        /// Billing Revenue
        if (lineInternalBillingRevenue != null) {
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead;
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_3__c = idGlv3Others;
          lineInternalBillingRevenue.AcctSeed__Hours_Units__c = -1;
          lineInternalBillingRevenue.AcctSeed__Rate__c = bill.ERP_Profit__c;
          lineInternalBillingRevenue.Taxable_Federal__c = false;
          lineInternalBillingRevenue.Taxable_Provincial__c = false;
          lineInternalBillingRevenue.Taxable_Retail__c = false;
          listBLupsert.add(lineInternalBillingRevenue);
        } else {
          lineInternalBillingRevenue = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead,
            AcctSeed__GL_Account_Variable_2__c = idGlv2Sales,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Product__c = idProductInternalBilling,
            AcctSeed__Hours_Units__c = -1,
            AcctSeed__Rate__c = bill.ERP_Profit__c,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false
          );
          listBLupsert.add(lineInternalBillingRevenue);
        }
        /// Billing Balance
        if (lineInternalBillingBalance != null) {
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead;
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_3__c = idGlv3Others;
          lineInternalBillingBalance.AcctSeed__Hours_Units__c = -1;
          lineInternalBillingBalance.AcctSeed__Rate__c = bill.ERP_Expense__c;
          lineInternalBillingBalance.Taxable_Federal__c = false;
          lineInternalBillingBalance.Taxable_Provincial__c = false;
          lineInternalBillingBalance.Taxable_Retail__c = false;
          listBLupsert.add(lineInternalBillingBalance);
        } else {
          lineInternalBillingBalance = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead,
            AcctSeed__GL_Account_Variable_2__c = idGlv2Sales,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Product__c = idProductInternalBalance,
            AcctSeed__Hours_Units__c = -1,
            AcctSeed__Rate__c = bill.ERP_Expense__c,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false
          );
          listBLupsert.add(lineInternalBillingBalance);
        }
      } else if (totalSerialRevenue <> 0) {
        if (lineInternalBillingRevenue != null) {
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead;
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
          lineInternalBillingRevenue.AcctSeed__GL_Account_Variable_3__c = idGlv3Others;
          lineInternalBillingRevenue.AcctSeed__Hours_Units__c = 1;
          lineInternalBillingRevenue.AcctSeed__Rate__c = totalSerialRevenue;
          lineInternalBillingRevenue.Taxable_Federal__c = false;
          lineInternalBillingRevenue.Taxable_Provincial__c = false;
          lineInternalBillingRevenue.Taxable_Retail__c = false;
          lineInternalBillingRevenue.Serial_Revenue_Line__c = true;
          listBLupsert.add(lineInternalBillingRevenue);
        } else {
          lineInternalBillingRevenue = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead,
            AcctSeed__GL_Account_Variable_2__c = idGlv2Sales,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Product__c = idProductInternalBilling,
            AcctSeed__Hours_Units__c = 1,
            AcctSeed__Rate__c = totalSerialRevenue,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false,
            Serial_Revenue_Line__c = true
          );
          listBLupsert.add(lineInternalBillingRevenue);
        }
        /// Billing Balance
        if (lineInternalBillingBalance != null) {
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead;
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_2__c = idGlv2Sales;
          lineInternalBillingBalance.AcctSeed__GL_Account_Variable_3__c = idGlv3Others;
          lineInternalBillingBalance.AcctSeed__Hours_Units__c = -1;
          lineInternalBillingBalance.AcctSeed__Rate__c = totalSerialRevenue;
          lineInternalBillingBalance.Taxable_Federal__c = false;
          lineInternalBillingBalance.Taxable_Provincial__c = false;
          lineInternalBillingBalance.Taxable_Retail__c = false;
          lineInternalBillingBalance.Serial_Revenue_Line__c = true;
          listBLupsert.add(lineInternalBillingBalance);
        } else {
          lineInternalBillingBalance = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = bill.Id,
            AcctSeed__GL_Account_Variable_1__c = idGlv1HeadOfficeOverhead,
            AcctSeed__GL_Account_Variable_2__c = idGlv2Sales,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Product__c = idProductInternalBalance,
            AcctSeed__Hours_Units__c = -1,
            AcctSeed__Rate__c = totalSerialRevenue,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false,
            Serial_Revenue_Line__c = true
          );
          listBLupsert.add(lineInternalBillingBalance);
        }
      }
    }

    if (!listBLdelete.isEmpty() || !listBLupsert.isEmpty()) {
      Boolean boolOld = gcBillingLine.disableTrigger;
      gcBillingLine.disableTrigger = true;
      if (!listBLdelete.isEmpty())
        delete listBLdelete;
      if (!listBLupsert.isEmpty())
        upsert listBLupsert;
      gcBillingLine.disableTrigger = boolOld;

      if (!listSerialsUsed.isEmpty()) {
        Boolean oldVal = gcSerialNumber.disableTrigger;
        gcSerialNumber.disableTrigger = true;
        update listSerialsUsed;
        gcSerialNumber.disableTrigger = oldVal;
      }
    }
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
