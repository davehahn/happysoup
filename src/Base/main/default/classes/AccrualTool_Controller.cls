public class AccrualTool_Controller {
  public static Map<String, AccuralWrapper> groupingWrapper = new Map<String, AccuralWrapper>();
  public static ProductPriceWrapper prodPrice;
  public static Map<String, List<ProductPriceWrapper>> prodPriceMapExpense = new Map<String, List<ProductPriceWrapper>>();
  public static Map<String, List<ProductPriceWrapper>> prodPriceMapRevenue = new Map<String, List<ProductPriceWrapper>>();
  public static Map<String, List<ProductPriceWrapper>> prodPriceMapInsurance = new Map<String, List<ProductPriceWrapper>>();

  public static Map<String, Map<String, List<ProductPriceWrapper>>> departmentMapExpense = new Map<String, Map<String, List<ProductPriceWrapper>>>();
  public static Map<String, Map<String, List<ProductPriceWrapper>>> departmentMapRevenue = new Map<String, Map<String, List<ProductPriceWrapper>>>();
  public static Map<String, Map<String, List<ProductPriceWrapper>>> departmentMapInsurance = new Map<String, Map<String, List<ProductPriceWrapper>>>();

  public static Map<String, JournalEntryLineWrapper> jounralEntryLineWrapperExpense = new Map<String, JournalEntryLineWrapper>();
  public static Map<String, JournalEntryLineWrapper> jounralEntryLineWrapperRevenue = new Map<String, JournalEntryLineWrapper>();
  public static Map<String, JournalEntryLineWrapper> jounralEntryLineWrapperInsurance = new Map<String, JournalEntryLineWrapper>();
  public static List<JournalEntryLineWrapper> journalEntryLineWrapperList = new List<JournalEntryLineWrapper>();

  public static Map<String, Accrual_Tool_GLAccount_Setting__mdt> accrualSettingMap = new Map<String, Accrual_Tool_GLAccount_Setting__mdt>();
  public static List<Accrual_Tool_GLAccount_Setting__mdt> accrualSettings = [
    SELECT Id, Accrual_Type__c, GLAccount__c, GLV1__c, GLV2__c
    FROM Accrual_Tool_GLAccount_Setting__mdt
  ];

  public static Map<Id, String> glAccMap = new Map<Id, String>();
  public static Map<String, Id> glVMap = new Map<String, Id>();
  public static List<String> glAccounts = new List<String>();
  public static List<String> glVs = new List<String>();

  //Fetch Factory PriceBook
  public static Id factoryPriceBook = gcConstants.idPricebookFactory;
  public static Map<Id, Decimal> factoryPrice = new Map<Id, Decimal>();

  @AuraEnabled(Cacheable=true)
  public static Map<String, String> dateRanges() {
    Map<String, String> m = new Map<String, String>();
    Date earliestOpen = GCR_AccountingPeriod.dateEarliestOpen();
    m.put(
      'minDate',
      Datetime.newInstance(earliestOpen.year(), earliestOpen.month(), earliestOpen.day()).format('YYYY-MM-dd')
    );
    m.put('maxDate', Datetime.now().format('YYYY-MM-dd'));
    return m;
  }

  @AuraEnabled(Cacheable=true)
  public static AcctSeed__Project__c fetchERPData(String erpId) {
    system.debug('erpId >> ' + erpId);
    AcctSeed__Project__c erpRec;
    for (AcctSeed__Project__c erp : [
      SELECT
        Id,
        Name,
        Stage__c,
        AcctSeed__Status__c,
        Model_Name__c,
        (SELECT Id FROM Journal_Entries__r WHERE Name LIKE 'Accrual%')
      FROM AcctSeed__Project__c
      WHERE Id = :erpId
      LIMIT 1
    ]) {
      erpRec = erp;
    }
    return erpRec;
  }

  @AuraEnabled
  public static CommissionWrapper fetchCommissionRecords(String erpId) {
    system.debug('erpId >> ' + erpId);

    List<CommissionRecordWrapper> commissionRecordsList = new List<CommissionRecordWrapper>();
    List<CommissionPaymentWrapper> commPaymentWrapperList = new List<CommissionPaymentWrapper>();
    Map<String, List<CommissionPaymentRecordsWrapper>> commPaymentMap = new Map<String, List<CommissionPaymentRecordsWrapper>>();

    Boolean allReviewed = true;
    Decimal totalAmount = 0.0;

    List<AcctSeed__GL_Account__c> debitGLAcc = [
      SELECT id, name
      FROM AcctSeed__GL_Account__c
      WHERE Id = :gcConstants.idGlCommissionExpense
      LIMIT 1
    ];

    for (CommissionRecord2__c commissionRecord : [
      SELECT
        Id,
        Name,
        Status__c,
        Project_Task__r.Name,
        Project_Task__r.AcctSeed__Labor_GL_Account__c,
        Project_Task__r.AcctSeed__Labor_GL_Account__r.name,
        Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
        Project_Task__r.AcctSeed__GL_Account_Variable_1__r.name,
        Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
        Project_Task__r.AcctSeed__GL_Account_Variable_2__r.name,
        (SELECT id, Status__c, Amount__c, Commission_Record2__r.Name FROM Commission_Payments__r)
      FROM CommissionRecord2__c
      WHERE Project__c = :erpId
    ]) {
      if (allReviewed && commissionRecord.Status__c != 'Reviewed') {
        allReviewed = false;
      }
      commissionRecordsList.add(new CommissionRecordWrapper(commissionRecord));

      if (!commPaymentMap.containsKey(commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)) {
        commPaymentMap.put(
          commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          new List<CommissionPaymentRecordsWrapper>()
        );
      }
      for (CommissionPayment2__c commPmnt : commissionRecord.Commission_Payments__r) {
        totalAmount += commPmnt.Amount__c;
        if (debitGLAcc != null) {
          commPaymentMap.get(commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)
            .add(
              new CommissionPaymentRecordsWrapper(
                commissionRecord.Project_Task__r.Name,
                commissionRecord.Status__c,
                commPmnt.Amount__c,
                debitGLAcc[0].Id,
                debitGLAcc[0].name,
                commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_1__r.name,
                commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                commissionRecord.Project_Task__r.AcctSeed__GL_Account_Variable_2__r.name
              )
            );
        }
      }
    }

    for (String dept : commPaymentMap.keyset()) {
      commPaymentWrapperList.add(new CommissionPaymentWrapper(dept, commPaymentMap.get(dept)));
    }
    system.debug('commissionRecords >> ' + commissionRecordsList);
    system.debug('commPaymentWrapperList >> ' + commPaymentWrapperList);

    CommissionWrapper commWrapper = new CommissionWrapper(
      allReviewed,
      commissionRecordsList,
      commPaymentWrapperList,
      totalAmount
    );

    return commWrapper;
  }

  @AuraEnabled
  public static List<ProductWrapper> fetchSerializedProducts(String erpId) {
    system.debug('erpId >> ' + erpId);
    List<ProductWrapper> prodList = new List<ProductWrapper>();
    List<Id> prodIdList = new List<Id>();
    for (AcctSeedERP__Material__c material : [
      SELECT
        id,
        GMBLASERP__Serial_Number__c,
        GMBLASERP__Serial_Number__r.Name,
        GMBLASERP__Serial_Number__r.Status__c,
        GMBLASERP__Serial_Number__r.Location__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
        AcctSeedERP__Product__r.Status__c,
        AcctSeedERP__Product__r.Physical_Location__c
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = TRUE
        AND GMBLASERP__Serial_Number__c != NULL
        AND AcctSeedERP__Project__c = :erpId
    ]) {
      prodList.add(
        new ProductWrapper(
          material.GMBLASERP__Serial_Number__r.Name,
          material.AcctSeedERP__Product__r.Name,
          material.GMBLASERP__Serial_Number__r.Status__c,
          material.GMBLASERP__Serial_Number__r.Location__c
        )
      );
      prodIdList.add(material.AcctSeedERP__Product__c);
      //prodList.add(new ProductWrapper(material.Serial_Number__c,material.AcctSeedERP__Product__r.Name,material.AcctSeedERP__Product__r.Status__c,material.AcctSeedERP__Product__r.Physical_Location__c ));
    }
    //        for(Product2 prod : [Select Id,Name,Status__c,(Select Id,Name,Status__c,Location__c From GMBLASERP__Serial_Numbers__r) From Product2 Where Id IN: prodIdList])
    //        {
    //            for(GMBLASERP__Serial_Number__c sn : prod.GMBLASERP__Serial_Numbers__r) {
    //                prodList.add(new ProductWrapper(sn.Name,prod.Name,sn.Status__c,sn.Location__c ));
    //                break;
    //            }
    //        }
    system.debug('prodList >> ' + prodList);
    return prodList;
  }

  public static void fetchFactoryPrice(String erpId) {
    for (Product2 prod : [
      SELECT
        Id,
        Landed_Unit_Cost__c,
        Partner_Price__c,
        (
          SELECT Id, UnitPrice
          FROM PricebookEntries
          WHERE
            Pricebook2Id = :factoryPriceBook
            AND Product2Id IN (
              SELECT AcctSeedERP__Product__c
              FROM AcctSeedERP__Material__c
              WHERE AcctSeedERP__Project__c = :erpId
            )
          ORDER BY CreatedDate DESC
          LIMIT 1
        )
      FROM Product2
    ]) {
      for (PricebookEntry pbe : prod.PricebookEntries) {
        factoryPrice.put(prod.Id, pbe.UnitPrice);
      }
    }
  }
  public static void processERPLine(AcctSeedERP__Material__c material) {
    prodPrice = new ProductPriceWrapper(
      material.AcctSeedERP__Product__r.Name,
      material.GMBLASERP__Total_Price__c,
      material.AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c
    );
    if (
      material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c != null &&
      material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.AcctSeed__Type__c == 'Expense' // Expense GL Account
    ) {
      system.debug('Expense Type >> ');
      //process for both Expense and Insurance
      if (material.AcctSeedERP__Product__r.RecordType.Name == 'Insurance') {
        if (
          !departmentMapInsurance.containsKey(
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
          )
        ) {
          departmentMapInsurance.put(
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
            new Map<String, List<ProductPriceWrapper>>()
          );
        }
        prodPriceMapInsurance = departmentMapInsurance.get(
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
        );

        if (!prodPriceMapInsurance.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name)) {
          prodPriceMapInsurance.put(
            material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
            new List<ProductPriceWrapper>()
          );
        }
        prodPriceMapInsurance.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name).add(prodPrice);

        departmentMapInsurance.put(
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          prodPriceMapInsurance
        );
        system.debug('prodPriceMapInsurance >> ' + prodPriceMapInsurance);
        String key =
          material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c +
          '' +
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c +
          '' +
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;

        Decimal profitPercent = material.AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c;
        profitPercent = (profitPercent == null) ? 50.00 : profitPercent;
        Decimal debitAmt = (material.GMBLASERP__Total_Price__c) * (1 - (profitPercent / 100));
        if (!jounralEntryLineWrapperInsurance.containsKey(key)) {
          jounralEntryLineWrapperInsurance.put(
            key,
            new JournalEntryLineWrapper(
              material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
              material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
              material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
              material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
              material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
              material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
              debitAmt,
              0.0
            )
          );
        } else {
          JournalEntryLineWrapper Insurance = jounralEntryLineWrapperInsurance.get(key);
          Insurance.Debit = Insurance.Debit + debitAmt;
          jounralEntryLineWrapperInsurance.put(key, Insurance);
        }
      } else {
        //Use factory price here
        ProductPriceWrapper newProdPrice = prodPrice;
        if (factoryPrice.containsKey(material.AcctSeedERP__Product__c)) {
          newProdPrice = new ProductPriceWrapper(
            material.AcctSeedERP__Product__r.Name,
            factoryPrice.get(material.AcctSeedERP__Product__c),
            material.AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c
          );
        } else {
          newProdPrice = new ProductPriceWrapper(
            material.AcctSeedERP__Product__r.Name,
            0.0,
            material.AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c
          );
          //return;
        }
        if (
          !departmentMapExpense.containsKey(
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
          )
        ) {
          departmentMapExpense.put(
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
            new Map<String, List<ProductPriceWrapper>>()
          );
        }
        prodPriceMapExpense = departmentMapExpense.get(
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
        );

        if (!prodPriceMapExpense.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name)) {
          prodPriceMapExpense.put(
            material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
            new List<ProductPriceWrapper>()
          );
        }
        prodPriceMapExpense.get(material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name)
          .add(newProdPrice);

        departmentMapExpense.put(
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          prodPriceMapExpense
        );
        system.debug('prodPriceMapExpense >> ' + prodPriceMapExpense);
        String key =
          material.AcctSeedERP__Product__c +
          '' +
          material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c +
          '' +
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c +
          '' +
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;

        if (!jounralEntryLineWrapperExpense.containsKey(key)) {
          JournalEntryLineWrapper jew = new JournalEntryLineWrapper(
            material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
            material.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
            material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
            newProdPrice.price,
            0.0
          );
          jew.ProductId = material.AcctSeedERP__Product__c;
          jounralEntryLineWrapperExpense.put(key, jew);
        } else {
          JournalEntryLineWrapper Expense = jounralEntryLineWrapperExpense.get(key);
          Expense.Debit = Expense.Debit + newProdPrice.price;
          if (Expense.ProductId == null)
            Expense.ProductId = material.AcctSeedERP__Product__c;
          jounralEntryLineWrapperExpense.put(key, Expense);
        }
      }
    }
    if (
      material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c != null &&
      material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c == 'Revenue'
    ) {
      system.debug('revenue GL >> ');
      //process for Revenue

      if (
        !departmentMapRevenue.containsKey(material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name)
      ) {
        departmentMapRevenue.put(
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          new Map<String, List<ProductPriceWrapper>>()
        );
      }
      prodPriceMapRevenue = departmentMapRevenue.get(
        material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
      );

      if (!prodPriceMapRevenue.containsKey(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name)) {
        prodPriceMapRevenue.put(
          material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name,
          new List<ProductPriceWrapper>()
        );
      }
      prodPriceMapRevenue.get(material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name).add(prodPrice);

      departmentMapRevenue.put(
        material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
        prodPriceMapRevenue
      );
      system.debug('prodPriceMapRevenue >> ' + prodPriceMapRevenue);
      String key =
        material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c +
        '' +
        material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c +
        '' +
        material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c;
      if (!jounralEntryLineWrapperRevenue.containsKey(key)) {
        JournalEntryLineWrapper jelw = new JournalEntryLineWrapper(
          material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c,
          material.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name,
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
          material.AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name,
          0.0,
          material.GMBLASERP__Total_Price__c
        );
        jelw.ProductId = material.AcctSeedERP__Product__c;
        jounralEntryLineWrapperRevenue.put(key, jelw);
      } else {
        JournalEntryLineWrapper Revenue = jounralEntryLineWrapperRevenue.get(key);
        Revenue.Credit = Revenue.Credit + material.GMBLASERP__Total_Price__c;
        if (Revenue.ProductId == null) {
          Revenue.ProductId = material.AcctSeedERP__Product__c;
        }
        jounralEntryLineWrapperRevenue.put(key, Revenue);
      }
    }
  }

  public static void processJournalLines(String erpId) {
    Decimal journalDebitTotal = 0.0;
    Decimal journalCreditTotal = 0.0;
    Decimal revenueGLTotal = 0.0;

    AcctSeed__Project__c erpRec;

    for (AcctSeed__Project__c erp : [
      SELECT
        Id,
        Name,
        GL_Account_Variable_1__c,
        GL_Account_Variable_1__r.Name,
        GL_Account_Variable_2__c,
        GL_Account_Variable_2__r.Name,
        (SELECT Id FROM Journal_Entries__r WHERE Name LIKE 'Accrual%')
      FROM AcctSeed__Project__c
      WHERE Id = :erpId
      LIMIT 1
    ]) {
      erpRec = erp;
    }
    glAccounts.add(gcConstants.idGlAccruedRevenue);
    glAccounts.add(gcConstants.idGlAccruedExpenses);
    glAccounts.add(gcConstants.idGlCommissionExpense);

    for (AcctSeed__GL_Account__c glAcc : [SELECT Id, Name FROM AcctSeed__GL_Account__c WHERE Id IN :glAccounts]) {
      glAccMap.put(glAcc.Id, glAcc.Name);
    }

    for (JournalEntryLineWrapper lineWrapper : jounralEntryLineWrapperRevenue.values()) {
      revenueGLTotal += lineWrapper.Credit;
      journalCreditTotal += lineWrapper.Credit;
      JournalEntryLineWrapper jelw = new JournalEntryLineWrapper(
        gcConstants.idGlAccruedRevenue,
        glAccMap.get(gcConstants.idGlAccruedRevenue),
        erpRec.GL_Account_Variable_1__c,
        erpRec.GL_Account_Variable_1__r.Name,
        erpRec.GL_Account_Variable_2__c,
        erpRec.GL_Account_Variable_2__r.Name,
        lineWrapper.Credit,
        0.0
      );
      jelw.ProductId = lineWrapper.ProductId;
      journalEntryLineWrapperList.add(jelw);
    }
    //        JournalEntryLineWrapper revenueGL = new JournalEntryLineWrapper(
    //            gcConstants.idGlAccruedRevenue,glAccMap.get(gcConstants.idGlAccruedRevenue),
    //            erpRec.GL_Account_Variable_1__c,erpRec.GL_Account_Variable_1__r.Name,
    //            erpRec.GL_Account_Variable_2__c,erpRec.GL_Account_Variable_2__r.Name,
    //            revenueGLTotal,0.0
    //        );
    journalDebitTotal += revenueGLTotal;

    Decimal expenseGLTotal = 0.0;
    for (JournalEntryLineWrapper lineWrapper : jounralEntryLineWrapperExpense.values()) {
      expenseGLTotal += lineWrapper.Debit;
      journalDebitTotal += lineWrapper.Debit;
    }
    JournalEntryLineWrapper expenseGL = new JournalEntryLineWrapper(
      gcConstants.idGlAccruedExpenses,
      glAccMap.get(gcConstants.idGlAccruedExpenses),
      erpRec.GL_Account_Variable_1__c,
      erpRec.GL_Account_Variable_1__r.Name,
      erpRec.GL_Account_Variable_2__c,
      erpRec.GL_Account_Variable_2__r.Name,
      0.0,
      expenseGLTotal
    );
    journalCreditTotal += expenseGLTotal;

    Decimal insuranceGLTotal = 0.0;
    for (JournalEntryLineWrapper lineWrapper : jounralEntryLineWrapperInsurance.values()) {
      insuranceGLTotal += lineWrapper.Debit;
      journalDebitTotal += lineWrapper.Debit;
    }
    JournalEntryLineWrapper insuranceGL = new JournalEntryLineWrapper(
      gcConstants.idGlAccruedExpenses,
      glAccMap.get(gcConstants.idGlAccruedExpenses),
      erpRec.GL_Account_Variable_1__c,
      erpRec.GL_Account_Variable_1__r.Name,
      erpRec.GL_Account_Variable_2__c,
      erpRec.GL_Account_Variable_2__r.Name,
      0.0,
      insuranceGLTotal
    );
    journalCreditTotal += insuranceGLTotal;

    Map<string, JournalEntryLineWrapper> jounralEntryLineWrapperCommission = new Map<string, JournalEntryLineWrapper>();
    CommissionWrapper commWrapper = fetchCommissionRecords(erpId);

    for (CommissionPaymentWrapper commPaymentWrapper : commWrapper.commPaymentWrapper) {
      for (CommissionPaymentRecordsWrapper commPayments : commPaymentWrapper.commPayments) {
        String key = commPayments.GLAccountId + '' + commPayments.GLV1Id + '' + commPayments.GLV2Id;
        if (!jounralEntryLineWrapperCommission.containsKey(key)) {
          jounralEntryLineWrapperCommission.put(
            key,
            new JournalEntryLineWrapper(
              commPayments.GLAccountId,
              commPayments.GLAccountName,
              commPayments.GLV1Id,
              commPayments.GLV1Name,
              commPayments.GLV2Id,
              commPayments.GLV2Name,
              commPayments.Amount,
              0.0
            )
          );
        } else {
          JournalEntryLineWrapper commission = jounralEntryLineWrapperCommission.get(key);
          commission.Debit = commission.Debit + commPayments.Amount;
          jounralEntryLineWrapperCommission.put(key, commission);
        }
      }
    }
    Decimal commissionGLTotal = 0.0;
    for (JournalEntryLineWrapper lineWrapper : jounralEntryLineWrapperCommission.values()) {
      commissionGLTotal += lineWrapper.Debit;
      journalCreditTotal += lineWrapper.Debit;
    }
    JournalEntryLineWrapper commissionGL = new JournalEntryLineWrapper(
      gcConstants.idGlAccruedExpenses,
      glAccMap.get(gcConstants.idGlAccruedExpenses),
      //gcConstants.idGlCommissionExpense,glAccMap.get(gcConstants.idGlCommissionExpense),
      erpRec.GL_Account_Variable_1__c,
      erpRec.GL_Account_Variable_1__r.Name,
      erpRec.GL_Account_Variable_2__c,
      erpRec.GL_Account_Variable_2__r.Name,
      0.0,
      commissionGLTotal
    );
    journalDebitTotal += commissionGLTotal;

    groupingWrapper.put('TotalDebit', new AccuralWrapper(journalDebitTotal, null, null));
    groupingWrapper.put('TotalCredit', new AccuralWrapper(journalCreditTotal, null, null));

    journalEntryLineWrapperList.addAll(jounralEntryLineWrapperRevenue.values());
    //journalEntryLineWrapperList.add(revenueGL);
    journalEntryLineWrapperList.addAll(jounralEntryLineWrapperExpense.values());
    journalEntryLineWrapperList.add(expenseGL);
    journalEntryLineWrapperList.addAll(jounralEntryLineWrapperInsurance.values());
    journalEntryLineWrapperList.add(insuranceGL);
    journalEntryLineWrapperList.addAll(jounralEntryLineWrapperCommission.values());
    journalEntryLineWrapperList.add(commissionGL);

    system.debug('journalEntryLineWrapperList >> ' + journalEntryLineWrapperList);
    groupingWrapper.put('JournalLines', new AccuralWrapper(null, null, journalEntryLineWrapperList));
  }

  public static void processRevenueWrapper() {
    List<DepartmentWrapper> revenueWrapper = new List<DepartmentWrapper>();
    Decimal totalAmount = 0.0;
    for (String department : departmentMapRevenue.keyset()) {
      List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
      Map<String, List<ProductPriceWrapper>> tmpMap = departmentMapRevenue.get(department);
      for (String glAccount : tmpMap.keyset()) {
        Decimal totalPrice = 0.0;
        Decimal totalCost = 0.0;
        for (ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
          totalPrice += prodPriceVar.price;
          totalAmount += prodPriceVar.price;
          totalCost += prodPriceVar.cost;
        }

        lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount), glAccount, totalPrice, totalCost));
      }
      revenueWrapper.add(new DepartmentWrapper(department, lineItemWrapp));
    }
    groupingWrapper.put('Revenue', new AccuralWrapper(totalAmount, revenueWrapper, null));
  }

  public static void processExpenseWrapper() {
    List<DepartmentWrapper> expenseWrapper = new List<DepartmentWrapper>();

    Decimal totalAmount = 0.0;
    for (String department : departmentMapExpense.keyset()) {
      List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
      Map<String, List<ProductPriceWrapper>> tmpMap = departmentMapExpense.get(department);
      for (String glAccount : tmpMap.keyset()) {
        Decimal totalPrice = 0.0;
        Decimal totalCost = 0.0;
        for (ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
          totalPrice += prodPriceVar.price;
          totalAmount += prodPriceVar.price;
          totalCost += prodPriceVar.cost;
        }

        lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount), glAccount, totalPrice, totalCost));
      }
      expenseWrapper.add(new DepartmentWrapper(department, lineItemWrapp));
    }
    groupingWrapper.put('Expense', new AccuralWrapper(totalAmount, expenseWrapper, null));
  }

  public static void processInsuranceWrapper() {
    List<DepartmentWrapper> InsuranceWrapper = new List<DepartmentWrapper>();

    Decimal totalAmount = 0.0;
    for (String department : departmentMapInsurance.keyset()) {
      List<LineItemWrapper> lineItemWrapp = new List<LineItemWrapper>();
      Map<String, List<ProductPriceWrapper>> tmpMap = departmentMapInsurance.get(department);
      for (String glAccount : tmpMap.keyset()) {
        Decimal totalPrice = 0.0;
        Decimal totalCost = 0.0;
        for (ProductPriceWrapper prodPriceVar : tmpMap.get(glAccount)) {
          totalPrice += prodPriceVar.price;
          totalAmount += prodPriceVar.cost;
          totalCost += prodPriceVar.cost;
        }

        lineItemWrapp.add(new LineItemWrapper(tmpMap.get(glAccount), glAccount, totalPrice, totalCost));
      }
      insuranceWrapper.add(new DepartmentWrapper(department, lineItemWrapp));
    }
    groupingWrapper.put('Insurance', new AccuralWrapper(totalAmount, insuranceWrapper, null));
  }

  @AuraEnabled
  public static Map<String, AccuralWrapper> fetchOrderLines(String erpId) {
    system.debug('erpId >> ' + erpId);

    fetchFactoryPrice(erpId);

    for (AcctSeedERP__Material__c material : [
      SELECT
        id,
        Serial_Number__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Name,
        GMBLASERP__Total_Price__c,
        AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
        AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
        AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.AcctSeed__Type__c,
        AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c,
        AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name,
        AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
        AcctSeedERP__Product__r.RecordType.Name,
        AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c,
        AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
        AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
        AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
        AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erpId
    ]) {
      processERPLine(material);
    }

    processJournalLines(erpId);
    processRevenueWrapper();
    processExpenseWrapper();
    processInsuranceWrapper();

    system.debug('groupingWrapper >> ' + groupingWrapper);
    return groupingWrapper;
  }

  @AuraEnabled
  public static String createJournalEntry(String erpId, String jounralEntryDate) {
    system.debug('erpId >> ' + erpId);
    system.debug('jounralEntryDate >> ' + jounralEntryDate);

    String message = 'Journal Entry Created!';
    Map<String, AccuralWrapper> groupingWrapper = fetchOrderLines(erpId);
    AccuralWrapper wrapper = groupingWrapper.get('JournalLines');
    List<JournalEntryLineWrapper> journalEntryLineWrapper = wrapper.journalEntryLineWrapper;

    Savepoint sp = Database.setSavepoint();
    try {
      Date jeDate = Date.valueOf(jounralEntryDate);

      AcctSeed__Project__c project = [
        SELECT Id, Name, Stage__c, AcctSeed__Status__c, AcctSeedERP__Work_Order_Number__c
        FROM AcctSeed__Project__c
        WHERE Id = :erpId
        LIMIT 1
      ];

      //List<AcctSeed__Journal_Entry__c> existingEntry = [Select Id From AcctSeed__Journal_Entry__c Where Project__c =:project.Id];

      List<AcctSeed__Journal_Entry_Line__c> journalEntries = new List<AcctSeed__Journal_Entry_Line__c>();
      AcctSeed__Journal_Entry__c journalEntry = new AcctSeed__Journal_Entry__c(
        Name = 'Accrual Entry - ' + project.Name,
        AcctSeed__Journal_Date__c = jeDate,
        AcctSeed__Status__c = 'Approved',
        Project__c = project.Id
      );

      //if(existingEntry.size() > 0) {
      //  journalEntry.Id = existingEntry[0].Id;
      //}

      insert journalEntry;

      //if(existingEntry.size() > 0) {
      // delete existing lines
      //    delete ([Select Id From AcctSeed__Journal_Entry_Line__c Where AcctSeed__Journal_Entry__c =:journalEntry.Id]);
      //}
      for (JournalEntryLineWrapper wrap : journalEntryLineWrapper) {
        AcctSeed__Journal_Entry_Line__c je = new AcctSeed__Journal_Entry_Line__c();
        je.AcctSeed__GL_Account__c = wrap.GLAccountId;
        /// SFISSUES - 1309
        //if(je.AcctSeed__GL_Account__c == gcConstants.idGlAccruedRevenue){
        je.Accrual_Product__c = wrap.ProductId;
        //}

        if (wrap.Credit != null && wrap.Credit != 0.0) {
          je.AcctSeed__Credit__c = wrap.Credit;
        } else {
          je.AcctSeed__Debit__c = wrap.Debit;
        }
        //je.AcctSeed__Project__c = project.Id;
        je.AcctSeed__GL_Account_Variable_1__c = wrap.GLV1Id;
        je.AcctSeed__GL_Account_Variable_2__c = wrap.GLV2Id;
        je.AcctSeed__Date__c = jeDate;
        je.AcctSeed__Units__c = 1;
        je.AcctSeed__Journal_Entry__c = journalEntry.Id;

        journalEntries.add(je);
      }

      try {
        insert journalEntries;
      } catch (Exception e) {
        message = 'Error while Jounral Entry Creation';
        system.debug('Exception : ' + e.getMessage());
        system.debug(e.getStackTraceString());
        return message;
      }

      try {
        /// New requirement to update a checkbox on ERP ater the accrual Journal Entry has been created.
        Boolean oldVal = gcProject.disableTrigger;
        gcProject.disableTrigger = true;
        update new AcctSeed__Project__c(Id = project.Id, Accrual_JE_created__c = true);
        gcProject.disableTrigger = oldVal;
        AcctSeed.JournalEntryPostService.postJournalEntries(new List<AcctSeed__Journal_Entry__c>{ journalEntry });
      } catch (Exception e) {
        message = 'Error while Posting Jounral Entry ' + e.getMessage();
        return message;
      }
    } catch (Exception e) {
      Database.rollback(sp);
      system.debug('Exception - ' + e);
      message = 'Error: ' + e.getMessage();
    }
    return message;
  }

  public class ProductWrapper {
    @AuraEnabled
    public string serialNumber;
    @AuraEnabled
    public string productName;
    @AuraEnabled
    public string Status;
    @AuraEnabled
    public string Location;

    public ProductWrapper(string serialNumber, string productName, string Status, string Location) {
      this.serialNumber = serialNumber;
      this.productName = productName;
      this.Status = Status;
      this.Location = Location;
    }
  }
  public class CommissionWrapper {
    @AuraEnabled
    public Boolean isReviewed;
    @AuraEnabled
    public List<CommissionRecordWrapper> commissionRecordsList;
    @AuraEnabled
    public List<CommissionPaymentWrapper> commPaymentWrapper;
    @AuraEnabled
    public Decimal totalAmount;

    public CommissionWrapper(
      Boolean isReviewed,
      List<CommissionRecordWrapper> commissionRecordsList,
      List<CommissionPaymentWrapper> commPaymentWrapper,
      Decimal totalAmount
    ) {
      this.isReviewed = isReviewed;
      this.commissionRecordsList = commissionRecordsList;
      this.commPaymentWrapper = commPaymentWrapper;
      this.totalAmount = totalAmount;
    }
  }
  public class CommissionRecordWrapper {
    @AuraEnabled
    public Boolean isReviewed;
    @AuraEnabled
    public CommissionRecord2__c commissionRecord;

    public CommissionRecordWrapper(CommissionRecord2__c commissionRecord) {
      this.commissionRecord = commissionRecord;
      this.isReviewed = commissionRecord.Status__c == 'Reviewed' ? true : false;
    }
  }
  public class CommissionPaymentWrapper {
    @AuraEnabled
    public String Department;
    @AuraEnabled
    public List<CommissionPaymentRecordsWrapper> commPayments;

    public CommissionPaymentWrapper(String Department, List<CommissionPaymentRecordsWrapper> commPayments) {
      this.Department = Department;
      this.commPayments = commPayments;
    }
  }
  public class CommissionPaymentRecordsWrapper {
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public Decimal Amount;
    @AuraEnabled
    public String GLAccountId;
    @AuraEnabled
    public String GLAccountName;
    @AuraEnabled
    public String GLV1Id;
    @AuraEnabled
    public String GLV1Name;
    @AuraEnabled
    public String GLV2Id;
    @AuraEnabled
    public String GLV2Name;

    public CommissionPaymentRecordsWrapper(
      String Name,
      String Status,
      Decimal Amount,
      String GLAccountId,
      String GLAccountName,
      String GLV1Id,
      String GLV1Name,
      String GLV2Id,
      String GLV2Name
    ) {
      this.Name = Name;
      this.Status = Status;
      this.Amount = Amount;
      this.GLAccountId = GLAccountId;
      this.GLAccountName = GLAccountName;
      this.GLV1Id = GLV1Id;
      this.GLV1Name = GLV1Name;
      this.GLV2Id = GLV2Id;
      this.GLV2Name = GLV2Name;
    }
  }

  public class AccuralWrapper {
    @AuraEnabled
    public Decimal totalAmount;
    @AuraEnabled
    public List<DepartmentWrapper> departmentWrapper;
    @AuraEnabled
    public List<JournalEntryLineWrapper> journalEntryLineWrapper;

    public AccuralWrapper(
      Decimal totalAmount,
      List<DepartmentWrapper> departmentWrapper,
      List<JournalEntryLineWrapper> journalEntryLineWrapper
    ) {
      this.departmentWrapper = departmentWrapper;
      this.journalEntryLineWrapper = journalEntryLineWrapper;
      this.totalAmount = totalAmount;
    }
  }
  public class DepartmentWrapper {
    @AuraEnabled
    public String Department;
    @AuraEnabled
    public List<LineItemWrapper> lineItemWrapperList;

    public DepartmentWrapper(String Department, List<LineItemWrapper> lineItemWrapperList) {
      this.lineItemWrapperList = lineItemWrapperList;
      this.Department = Department;
    }
  }
  public class LineItemWrapper {
    @AuraEnabled
    public List<ProductPriceWrapper> productPriceWrapperList;
    @AuraEnabled
    public String GLAccountName;
    @AuraEnabled
    public Decimal totalPrice;
    @AuraEnabled
    public Decimal totalCost;

    public LineItemWrapper(
      List<ProductPriceWrapper> productPriceWrapperList,
      String GLAccountName,
      Decimal totalPrice,
      Decimal totalCost
    ) {
      this.productPriceWrapperList = productPriceWrapperList;
      this.GLAccountName = GLAccountName;
      this.totalPrice = totalPrice;
      this.totalCost = totalCost;
    }
  }
  public class ProductPriceWrapper {
    @AuraEnabled
    public String productName;
    @AuraEnabled
    public String profit;
    @AuraEnabled
    public Decimal price;
    @AuraEnabled
    public Decimal cost;

    public ProductPriceWrapper(String productName, Decimal price, Decimal profitPercent) {
      this.productName = productName;
      this.price = price;
      String strProfit = String.valueOf(profitPercent);
      if (!String.isBlank(strProfit) && strProfit.indexOf('.') > 0) {
        strProfit = strProfit.substring(0, strProfit.indexOf('.'));
      }
      this.profit = profitPercent == null ? '50%' : strProfit + '%';
      Decimal percentOverride = profitPercent == null ? 50.00 : profitPercent;
      this.cost = price * (1 - (percentOverride / 100));
    }
  }
  public class JournalEntryLineWrapper {
    @AuraEnabled
    public String GLAccountId;
    @AuraEnabled
    public String ProductId;
    @AuraEnabled
    public String GLAccountName;
    @AuraEnabled
    public String GLV1Id;
    @AuraEnabled
    public String GLV1Name;
    @AuraEnabled
    public String GLV2Id;
    @AuraEnabled
    public String GLV2Name;
    @AuraEnabled
    public Decimal Debit;
    @AuraEnabled
    public Decimal Credit;

    public JournalEntryLineWrapper(
      String GLAccountId,
      String GLAccountName,
      String GLV1Id,
      String GLV1Name,
      String GLV2Id,
      String GLV2Name,
      Decimal Debit,
      Decimal Credit
    ) {
      this.GLAccountId = GLAccountId;
      this.GLAccountName = GLAccountName;
      this.GLV1Id = GLV1Id;
      this.GLV1Name = GLV1Name;
      this.GLV2Id = GLV2Id;
      this.GLV2Name = GLV2Name;
      this.Debit = Debit;
      this.Credit = Credit;
    }
  }
}
