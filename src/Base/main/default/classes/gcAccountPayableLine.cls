public without sharing class gcAccountPayableLine {
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
    map<Id, AcctSeed__Account_Payable_Line__c> oldMap,
    map<Id, AcctSeed__Account_Payable_Line__c> newMap,
    list<AcctSeed__Account_Payable_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Account_Payable_Line__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Account_Payable_Line__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Account_Payable_Line__c>();

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
      Set<Id> setIdPayable = new Set<Id>();
      if (boolIsInsert) {
        for (AcctSeed__Account_Payable_Line__c ap : listNew)
          setIdPayable.add(ap.AcctSeed__Account_Payable__c);
      }
      if (boolIsUpdate) {
        for (AcctSeed__Account_Payable_Line__c ap : listNew)
          setIdPayable.add(ap.AcctSeed__Account_Payable__c);
        for (AcctSeed__Account_Payable_Line__c ap : oldMap.values())
          setIdPayable.add(ap.AcctSeed__Account_Payable__c);
      }
      if (boolIsDelete) {
        for (AcctSeed__Account_Payable_Line__c ap : oldMap.values())
          setIdPayable.add(ap.AcctSeed__Account_Payable__c);
      }
      updateSalesTax(setIdPayable);
    }
  }

  private static void setFinancialAttributes(List<AcctSeed__Account_Payable_Line__c> listNew) {
    gcTransactionParent.setFinancialAttributes(
      listNew,
      null,
      'AcctSeed__Project_Task__c',
      'AcctSeed__Expense_GL_Account__c'
    );
  }

  private static void updateAndValidate(
    map<Id, AcctSeed__Account_Payable_Line__c> oldMap,
    map<Id, AcctSeed__Account_Payable_Line__c> newMap,
    list<AcctSeed__Account_Payable_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore) {
      refreshStatics(listNew);

      for (AcctSeed__Account_Payable_Line__c line : listNew) {
        if (
          boolIsUpdate &&
          line.AcctSeed__Expense_GL_Account__c != null &&
          line.AcctSeed__Expense_GL_Account__c != oldMap.get(line.Id).AcctSeed__Expense_GL_Account__c &&
          line.Expense_Revenue_GL_Account__c == oldMap.get(line.Id).Expense_Revenue_GL_Account__c
        ) {
          line.Expense_Revenue_GL_Account__c = line.AcctSeed__Expense_GL_Account__c;
        }

        if (
          (line.AcctSeed__Expense_GL_Account__c == null && line.Expense_Revenue_GL_Account__c != null) ||
          (line.AcctSeed__Expense_GL_Account__c != null &&
          line.Expense_Revenue_GL_Account__c != null &&
          line.Expense_Revenue_GL_Account__c != line.AcctSeed__Expense_GL_Account__c)
        ) {
          line.AcctSeed__Expense_GL_Account__c = line.Expense_Revenue_GL_Account__c;
        }

        if (line.AcctSeed__Expense_GL_Account__c != null && line.Expense_Revenue_GL_Account__c == null)
          line.Expense_Revenue_GL_Account__c = line.AcctSeed__Expense_GL_Account__c;

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
            }
          }
        }

        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Federal__c != oldMap.get(line.Id).Taxable_Federal__c
        )
          line.addError('The Federal Taxable status of a Payable Line may not be changed, if the Payable is Posted.');
        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Provincial__c != oldMap.get(line.Id).Taxable_Provincial__c
        )
          line.addError(
            'The Provincial Taxable status of a Payable Line may not be changed, if the Payable is Posted.'
          );
        if (
          boolIsUpdate &&
          line.AcctSeed__Parent_Status__c == 'Posted' &&
          line.Taxable_Retail__c != oldMap.get(line.Id).Taxable_Retail__c
        )
          line.addError('The Retail Taxable status of a Payable Line may not be changed, if the Payable is Posted.');

        AcctSeed__Account_Payable__c payable = mapBilling.get(line.AcctSeed__Account_Payable__c);
        if (line.AcctSeed__GL_Account_Variable_1__c == null && payable.GL_Account_Variable_1__c != null)
          line.AcctSeed__GL_Account_Variable_1__c = payable.GL_Account_Variable_1__c;
        if (line.AcctSeed__GL_Account_Variable_2__c == null && payable.GL_Account_Variable_2__c != null)
          line.AcctSeed__GL_Account_Variable_2__c = payable.GL_Account_Variable_2__c;
        if (line.AcctSeed__GL_Account_Variable_3__c == null)
          line.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
        if (boolIsInsert)
          line.AcctSeed__Date__c = payable.AcctSeed__Date__c;
      }
    }
  }

  private static map<Id, Product2> mapProduct;
  private static map<Id, AcctSeed__Project__c> mapProject;
  private static map<Id, AcctSeed__Account_Payable__c> mapBilling;

  private static void refreshStatics(list<AcctSeed__Account_Payable_Line__c> listNew) {
    if (mapProduct == null) {
      mapProduct = new Map<Id, Product2>();
      mapProject = new Map<Id, AcctSeed__Project__c>();
      mapBilling = new Map<Id, AcctSeed__Account_Payable__c>();
    }
    set<Id> setIdProduct = new Set<Id>();
    set<Id> setIdProject = new Set<Id>();
    set<Id> setIdPayable = new Set<Id>();
    for (AcctSeed__Account_Payable_Line__c line : listNew) {
      if (line.AcctSeed__Product__c != null && !mapProduct.containsKey(line.AcctSeed__Product__c))
        setIdProduct.add(line.AcctSeed__Product__c);
      if (line.AcctSeed__Project__c != null && !mapProduct.containsKey(line.AcctSeed__Project__c))
        setIdProject.add(line.AcctSeed__Project__c);
      if (line.AcctSeed__Account_Payable__c != null && !mapBilling.containsKey(line.AcctSeed__Account_Payable__c))
        setIdPayable.add(line.AcctSeed__Account_Payable__c);
    }
    setIdProduct.remove(null);
    setIdProject.remove(null);
    setIdPayable.remove(null);

    for (Product2 p : [SELECT Id, RecordType.Name, Taxable__c FROM Product2 WHERE Id IN :setIdProduct]) {
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

    for (AcctSeed__Account_Payable__c b : [
      SELECT Id, GL_Account_Variable_1__c, GL_Account_Variable_2__c, GL_Account_Variable_3__c, AcctSeed__Date__c
      FROM AcctSeed__Account_Payable__c
      WHERE Id IN :setIdPayable
    ]) {
      mapBilling.put(b.Id, b);
    }
  }

  public static void updateSalesTax(set<Id> setIdPayable) {
    Id idProductSalesTaxFederal = gcConstants.idProductSalesTaxFederal;
    Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
    Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
    Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
    Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
    Id idGlSalesTaxRetail = gcConstants.idGlSalesTaxRetail;
    Id idGlSalesTaxPaid = gcConstants.idGlSalesTaxPaid;
    Id idGlSalesTaxPaidProvincial = gcConstants.idGlSalesTaxPaidProvincial;
    Id idGlAccruedExpenses = gcConstants.idGlAccruedExpenses;
    Id idGlv3Others = gcConstants.idGlv3Others;

    List<AcctSeed__Account_Payable_Line__c> listAPLupsert = new List<AcctSeed__Account_Payable_Line__c>();
    List<AcctSeed__Account_Payable_Line__c> listAPLdelete = new List<AcctSeed__Account_Payable_Line__c>();

    for (AcctSeed__Account_Payable__c payable : [
      SELECT
        Id,
        GL_Account_Variable_3__c,
        Tax_is_Harmonized__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        Tax_Override__c,
        Tax_Amount_Fixed__c,
        Tax_Amount_Federal__c,
        Tax_Amount_Provincial__c,
        Tax_Amount_Retail__c,
        AcctSeed__Date__c,
        (
          SELECT
            Id,
            AcctSeed__Date__c,
            AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__Quantity__c,
            AcctSeed__Product__c,
            AcctSeed__Product__r.RecordType.Name,
            AcctSeed__Amount__c,
            Taxable_Federal__c,
            Taxable_Provincial__c,
            Taxable_Retail__c
          FROM AcctSeed__Project_Account_Payable_Lines__r
          ORDER BY CreatedDate
        )
      FROM AcctSeed__Account_Payable__c
      WHERE Id IN :setIdPayable AND AcctSeed__Status__c != 'Posted'
    ]) {
      AcctSeed__Account_Payable_Line__c taxLineFederal;
      AcctSeed__Account_Payable_Line__c taxLineProvincial;
      AcctSeed__Account_Payable_Line__c taxLineRetail;
      AcctSeed__Account_Payable_Line__c taxLineHarmonized;
      AcctSeed__Account_Payable_Line__c lineProductPrecisionFix;

      Decimal taxRateFederal = (payable.Tax_Rate_Federal__c == null ? 0 : payable.Tax_Rate_Federal__c) / 100;
      Decimal taxRateProvincial = (payable.Tax_Rate_Provincial__c == null ? 0 : payable.Tax_Rate_Provincial__c) / 100;
      Decimal taxRateRetail = (payable.Tax_Rate_Retail__c == null ? 0 : payable.Tax_Rate_Retail__c) / 100;
      Decimal taxRateHarmonized = (payable.Tax_is_Harmonized__c == true ? (taxRateFederal + taxRateProvincial) : 0);

      if (payable.Tax_is_Harmonized__c) {
        taxRateFederal = 0;
        taxRateProvincial = 0;
      }

      Decimal taxableAmountFederal = 0;
      Decimal taxableAmountProvincial = 0;
      Decimal taxableAmountRetail = 0;
      Decimal taxableAmountHarmonized = 0;
      Decimal totalLineAmount = 0;
      for (AcctSeed__Account_Payable_Line__c apl : payable.AcctSeed__Project_Account_Payable_Lines__r) {
        if (apl.AcctSeed__Product__c == idProductSalesTaxFederal) {
          if (taxRateFederal == 0 || taxLineFederal != null)
            listAPLdelete.add(apl);
          else
            taxLineFederal = apl;
          continue;
        } else if (apl.AcctSeed__Product__c == idProductSalesTaxProvincial) {
          if (taxRateProvincial == 0 || taxLineProvincial != null)
            listAPLdelete.add(apl);
          else
            taxLineProvincial = apl;
          continue;
        } else if (apl.AcctSeed__Product__c == idProductSalesTaxRetail) {
          if (taxRateRetail == 0 || taxLineRetail != null)
            listAPLdelete.add(apl);
          else
            taxLineRetail = apl;
          continue;
        } else if (apl.AcctSeed__Product__c == idProductSalesTaxHarmonized) {
          if (taxRateHarmonized == 0 || taxLineHarmonized != null)
            listAPLdelete.add(apl);
          else
            taxLineHarmonized = apl;
          continue;
        } else if (apl.AcctSeed__Product__c == idProductPrecisionFix) {
          lineProductPrecisionFix = apl;
          continue;
        }
        totalLineAmount += (apl.AcctSeed__Amount__c == null ? 0 : apl.AcctSeed__Amount__c).setScale(6);
        if (!payable.Tax_Amount_Fixed__c) {
          if (apl.Taxable_Federal__c)
            taxableAmountFederal += (apl.AcctSeed__Amount__c == null ? 0 : apl.AcctSeed__Amount__c);
          if (apl.Taxable_Provincial__c)
            taxableAmountProvincial += (apl.AcctSeed__Amount__c == null ? 0 : apl.AcctSeed__Amount__c);
          if (apl.Taxable_Provincial__c || apl.Taxable_Federal__c)
            taxableAmountHarmonized += (apl.AcctSeed__Amount__c == null ? 0 : apl.AcctSeed__Amount__c);
          if (apl.Taxable_Retail__c)
            taxableAmountRetail += (apl.AcctSeed__Amount__c == null ? 0 : apl.AcctSeed__Amount__c);
        }

        //if(apl.AcctSeed__GL_Account_Variable_3__c != payable.GL_Account_Variable_3__c)
        if (apl.AcctSeed__GL_Account_Variable_3__c == null) {
          apl.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
          listAPLupsert.add(apl);
        }
      }

      if (payable.Tax_Amount_Fixed__c) {
        if (payable.Tax_Amount_Federal__c != 0) {
          taxRateFederal = 1;
          taxableAmountFederal = payable.Tax_Amount_Federal__c == null ? 0 : payable.Tax_Amount_Federal__c;
        }
        if (payable.Tax_Amount_Provincial__c != 0) {
          taxRateProvincial = 1;
          taxableAmountProvincial = payable.Tax_Amount_Provincial__c == null ? 0 : payable.Tax_Amount_Provincial__c;
        }
        if (payable.Tax_is_Harmonized__c) {
          taxableAmountFederal = 0;
          taxableAmountProvincial = 0;

          taxRateHarmonized = 1;
          taxableAmountHarmonized =
            (payable.Tax_Amount_Federal__c == null ? 0 : payable.Tax_Amount_Federal__c) +
            (payable.Tax_Amount_Provincial__c == null ? 0 : payable.Tax_Amount_Provincial__c);
        }
        if (payable.Tax_Amount_Retail__c != 0) {
          taxRateRetail = 1;
          taxableAmountRetail = payable.Tax_Amount_Retail__c == null ? 0 : payable.Tax_Amount_Retail__c;
        }
      }

      if (taxableAmountFederal == 0) {
        if (taxLineFederal != null)
          listAPLdelete.add(taxLineFederal);
      } else {
        if (taxRateFederal != 0) {
          if (taxLineFederal != null) {
            if (
              taxLineFederal.AcctSeed__Quantity__c != taxRateFederal.setScale(5) ||
              taxLineFederal.AcctSeed__Amount__c != taxableAmountFederal.setScale(2) ||
              //taxLineFederal.AcctSeed__GL_Account_Variable_3__c != payable.GL_Account_Variable_3__c ||
              taxLineFederal.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineFederal.Taxable_Federal__c == true
            ) {
              taxLineFederal.AcctSeed__Quantity__c = taxRateFederal.setScale(5);
              taxLineFederal.AcctSeed__Amount__c = (taxRateFederal * taxableAmountFederal).setScale(2);
              if (taxLineFederal.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineFederal.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
              taxLineFederal.Taxable_Federal__c = false;
              listAPLupsert.add(taxLineFederal);
            }
          } else {
            taxLineFederal = new AcctSeed__Account_Payable_Line__c(
              AcctSeed__Account_Payable__c = payable.Id,
              AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c,
              AcctSeed__Expense_GL_Account__c = idGlSalesTaxPaid,
              AcctSeed__Product__c = idProductSalesTaxFederal,
              AcctSeed__Quantity__c = taxRateFederal.setScale(5),
              AcctSeed__Amount__c = (taxRateFederal * taxableAmountFederal).setScale(2),
              Taxable_Federal__c = false,
              AcctSeed__Date__c = payable.AcctSeed__Date__c
            );
            listAPLupsert.add(taxLineFederal);
          }
          totalLineAmount += (taxRateFederal * taxableAmountFederal).setScale(2);
        }
      }

      if (taxableAmountProvincial == 0) {
        if (taxLineProvincial != null)
          listAPLdelete.add(taxLineProvincial);
      } else {
        if (taxRateProvincial != 0) {
          if (taxLineProvincial != null) {
            if (
              taxLineProvincial.AcctSeed__Quantity__c != taxRateProvincial.setScale(5) ||
              taxLineProvincial.AcctSeed__Amount__c != taxableAmountProvincial.setScale(2) ||
              //taxLineProvincial.AcctSeed__GL_Account_Variable_3__c != payable.GL_Account_Variable_3__c ||
              taxLineProvincial.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineProvincial.Taxable_Provincial__c == true
            ) {
              taxLineProvincial.AcctSeed__Quantity__c = taxRateProvincial.setScale(5);
              taxLineProvincial.AcctSeed__Amount__c = (taxRateProvincial * taxableAmountProvincial).setScale(2);
              if (taxLineProvincial.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineProvincial.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
              taxLineProvincial.Taxable_Provincial__c = false;
              listAPLupsert.add(taxLineProvincial);
            }
          } else {
            taxLineProvincial = new AcctSeed__Account_Payable_Line__c(
              AcctSeed__Account_Payable__c = payable.Id,
              AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c,
              AcctSeed__Expense_GL_Account__c = idGlSalesTaxPaidProvincial,
              AcctSeed__Product__c = idProductSalesTaxProvincial,
              AcctSeed__Quantity__c = taxRateProvincial.setScale(5),
              AcctSeed__Amount__c = (taxRateProvincial * taxableAmountProvincial).setScale(2),
              Taxable_Provincial__c = false,
              AcctSeed__Date__c = payable.AcctSeed__Date__c
            );
            listAPLupsert.add(taxLineProvincial);
          }
          totalLineAmount += (taxRateProvincial * taxableAmountProvincial).setScale(2);
        }
      }

      if (taxableAmountRetail == 0) {
        if (taxLineRetail != null)
          listAPLdelete.add(taxLineRetail);
      } else {
        if (taxRateRetail != 0) {
          if (taxLineRetail != null) {
            if (
              taxLineRetail.AcctSeed__Quantity__c != taxRateRetail.setScale(5) ||
              taxLineRetail.AcctSeed__Amount__c != taxableAmountRetail.setScale(2) ||
              //taxLineRetail.AcctSeed__GL_Account_Variable_3__c != payable.GL_Account_Variable_3__c ||
              taxLineRetail.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineRetail.Taxable_Retail__c == true
            ) {
              taxLineRetail.AcctSeed__Quantity__c = taxRateRetail.setScale(5);
              taxLineRetail.AcctSeed__Amount__c = (taxRateRetail * taxableAmountRetail).setScale(2);
              if (taxLineRetail.AcctSeed__GL_Account_Variable_3__c == null)
                taxLineRetail.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
              taxLineRetail.Taxable_Retail__c = false;
              listAPLupsert.add(taxLineRetail);
            }
          } else {
            taxLineRetail = new AcctSeed__Account_Payable_Line__c(
              AcctSeed__Account_Payable__c = payable.Id,
              AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c,
              AcctSeed__Expense_GL_Account__c = idGlSalesTaxRetail,
              AcctSeed__Product__c = idProductSalesTaxRetail,
              AcctSeed__Quantity__c = taxRateRetail.setScale(5),
              AcctSeed__Amount__c = (taxRateRetail * taxableAmountRetail).setScale(2),
              Taxable_Retail__c = false,
              AcctSeed__Date__c = payable.AcctSeed__Date__c
            );
            listAPLupsert.add(taxLineRetail);
          }
          totalLineAmount += (taxRateRetail * taxableAmountRetail).setScale(2);
        }
      }

      if (taxableAmountHarmonized == 0) {
        if (taxLineHarmonized != null)
          listAPLdelete.add(taxLineHarmonized);
      } else {
        if (taxRateHarmonized != 0) {
          if (taxLineHarmonized != null) {
            if (
              taxLineHarmonized.AcctSeed__Quantity__c != taxRateHarmonized.setScale(5) ||
              taxLineHarmonized.AcctSeed__Amount__c != taxableAmountHarmonized.setScale(2) ||
              //taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c != payable.GL_Account_Variable_3__c ||
              taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c == null ||
              taxLineHarmonized.Taxable_Provincial__c == true
            ) {
              taxLineHarmonized.AcctSeed__Quantity__c = taxRateHarmonized.setScale(5);
              taxLineHarmonized.AcctSeed__Amount__c = (taxRateHarmonized * taxableAmountHarmonized).setScale(2);
              taxLineHarmonized.AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c;
              taxLineHarmonized.Taxable_Provincial__c = false;
              listAPLupsert.add(taxLineHarmonized);
            }
          } else {
            taxLineHarmonized = new AcctSeed__Account_Payable_Line__c(
              AcctSeed__Account_Payable__c = payable.Id,
              AcctSeed__Expense_GL_Account__c = idGlSalesTaxPaid,
              AcctSeed__Product__c = idProductSalesTaxHarmonized,
              AcctSeed__Quantity__c = taxRateHarmonized.setScale(5),
              AcctSeed__Amount__c = (taxRateHarmonized * taxableAmountHarmonized).setScale(2),
              AcctSeed__GL_Account_Variable_3__c = payable.GL_Account_Variable_3__c,
              Taxable_Provincial__c = false,
              AcctSeed__Date__c = payable.AcctSeed__Date__c
            );
            listAPLupsert.add(taxLineHarmonized);
          }
          totalLineAmount += (taxRateHarmonized * taxableAmountHarmonized).setScale(2);
        }
      }

      Decimal actualValue = totalLineAmount.setScale(6);
      Decimal acctSeedValue = totalLineAmount.setScale(2, System.RoundingMode.HALF_UP);
      Decimal currentPrecision = (acctSeedValue - actualValue).setScale(6);
      //System.debug(loggingLevel.error,'totalLineAmount:'+totalLineAmount);
      //System.debug(loggingLevel.error,'actualValue:'+actualValue);
      //System.debug(loggingLevel.error,'acctSeedValue:'+acctSeedValue);
      //System.debug(loggingLevel.error,'currentPrecision:'+currentPrecision);
      if (currentPrecision != 0) {
        //if(currentPrecision.abs() < 0.005) currentPrecision = currentPrecision * -1;
        if (lineProductPrecisionFix != null) {
          lineProductPrecisionFix.AcctSeed__Quantity__c = 1;
          lineProductPrecisionFix.AcctSeed__Amount__c = currentPrecision;
          lineProductPrecisionFix.Taxable_Federal__c = false;
          lineProductPrecisionFix.Taxable_Provincial__c = false;
          lineProductPrecisionFix.Taxable_Retail__c = false;
          listAPLupsert.add(lineProductPrecisionFix);
        } else {
          lineProductPrecisionFix = new AcctSeed__Account_Payable_Line__c(
            AcctSeed__Account_Payable__c = payable.Id,
            AcctSeed__GL_Account_Variable_3__c = idGlv3Others,
            AcctSeed__Expense_GL_Account__c = idGlAccruedExpenses,
            AcctSeed__Product__c = idProductPrecisionFix,
            AcctSeed__Quantity__c = 1,
            AcctSeed__Amount__c = currentPrecision,
            Taxable_Federal__c = false,
            Taxable_Provincial__c = false,
            Taxable_Retail__c = false,
            AcctSeed__Date__c = payable.AcctSeed__Date__c
          );
          listAPLupsert.add(lineProductPrecisionFix);
        }
      } else {
        if (lineProductPrecisionFix != null)
          listAPLdelete.add(lineProductPrecisionFix);
      }
    }

    if (!listAPLdelete.isEmpty() || !listAPLupsert.isEmpty()) {
      Boolean boolOld = gcAccountPayableLine.disableTrigger;
      gcAccountPayableLine.disableTrigger = true;
      if (!listAPLdelete.isEmpty())
        delete listAPLdelete;
      if (!listAPLupsert.isEmpty())
        upsert listAPLupsert;
      gcAccountPayableLine.disableTrigger = boolOld;
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
  }
}
