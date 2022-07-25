public with sharing class OpportunityLexController {
  public class DataWrapper {
    public Decimal deposit { get; set; }
    public Decimal intrestRate { get; set; }
    public Integer finTerm { get; set; }
    public Integer finAmort { get; set; }
    public Integer insTerm { get; set; }

    public DataWrapper() {
    }
  }

  public class RecordWrapper {
    public Decimal deposit { get; set; }
    public Decimal intrestRate { get; set; }
    public Integer finTerm { get; set; }
    public Integer finAmort { get; set; }
    public Integer insTerm { get; set; }
    public Decimal preInsuranceAmount { get; set; }
    public Decimal insuranceTaxRate { get; set; }
    public List<BusinessOffice_Controller.SelectedInsuranceItem> insuranceLines { get; set; }

    public RecordWrapper(String recordId) {
      this.insuranceLines = new List<BusinessOffice_Controller.SelectedInsuranceItem>();
      String objType = LGND_Utilities.sObjectNameFromId(recordId);
      if (objType == 'Opportunity')
        processAsOpp(recordId);
      if (objType == 'AcctSeed__Project__c')
        processAsErp(recordId);
    }

    private void processAsOpp(String recordId) {
      Opportunity opp = fetchOpp(String.valueOf(recordId));
      this.deposit = opp.Deposit__c == null ? 0 : opp.Deposit__c;
      this.intrestRate = opp.Finance_Annual_Interest__c == null ? 0 : opp.Finance_Annual_Interest__c;
      this.finTerm = opp.Finance_Term__c == null ? 0 : Integer.valueOf(opp.Finance_Term__c);
      this.finAmort = Integer.valueOf(opp.Finance_Ammortization__c);
      this.insTerm = opp.Insurance_Term__c == null ? 0 : Integer.valueOf(opp.Insurance_Term__c);
      this.preInsuranceAmount = opp.Pre_Insurance_Total__c == null ? 0 : opp.Pre_Insurance_Total__c;
      this.insuranceTaxRate = opp.Tax_Rate_Retail__c;
      for (OpportunityLineItem oli : opp.OpportunityLineItems) {
        this.insuranceLines.add(new BusinessOffice_Controller.SelectedInsuranceItem(oli));
      }
    }

    private void processAsErp(String recordId) {
      AcctSeed__Project__c erp = fetchERP(String.valueOf(recordId));
      this.deposit = erp.Deposit__c == null ? 0 : erp.Deposit__c;
      this.intrestRate = erp.Finance_Annual_Interest__c == null ? 0 : erp.Finance_Annual_Interest__c;
      this.finTerm = erp.Finance_Term__c == null ? 0 : Integer.valueOf(erp.Finance_Term__c);
      this.finAmort = Integer.valueOf(erp.Finance_Ammortization__c);
      this.insTerm = erp.Insurance_Term__c == null ? 0 : Integer.valueOf(erp.Insurance_Term__c);
      this.preInsuranceAmount = erp.Pre_Insurance_Total__c == null ? 0 : erp.Pre_Insurance_Total__c;
      this.insuranceTaxRate = erp.Tax_Rate_Retail__c;
      AcctSeed__Project_Task__c[] tasks = fetchErpOrderTasks(recordId);
      for (AcctSeed__Project_Task__c t : tasks) {
        for (AcctSeedERP__Material__c mat : t.AcctSeedERP__Materials__r) {
          this.insuranceLines.add(new BusinessOffice_Controller.SelectedInsuranceItem(mat));
        }
      }
    }

    @TestVisible
    private Opportunity fetchOpp(String recordId) {
      return [
        SELECT
          Id,
          Deposit__c,
          Finance_Ammortization__c,
          Finance_Annual_Interest__c,
          Finance_Term__c,
          Insurance_Term__c,
          Tax_Rate_Retail__c,
          Pre_Insurance_Total__c,
          (
            SELECT
              Id,
              PricebookEntryId,
              Product2Id,
              Product2.Is_Residual_Insurance__c,
              Product2.Family,
              InsuranceCoverage__c,
              Insurance_Rate__c,
              UnitPrice
            FROM OpportunityLineItems
            WHERE IsInsurance__c = TRUE
          )
        FROM Opportunity
        WHERE Id = :recordId
      ];
    }

    private AcctSeed__Project__c fetchERP(String recordId) {
      return [
        SELECT
          Id,
          Deposit__c,
          Finance_Ammortization__c,
          Finance_Term__c,
          Finance_Annual_Interest__c,
          Insurance_Term__c,
          Tax_Rate_Retail__c,
          Pre_Insurance_Total__c
        FROM AcctSeed__Project__c
        WHERE Id = :recordId
      ];
    }

    private AcctSeed__Project_Task__c[] fetchErpOrderTasks(String recordId) {
      return [
        SELECT
          Id,
          (
            SELECT
              Id,
              AcctSeedERP__Product__c,
              AcctSeedERP__Product__r.Is_Residual_Insurance__c,
              AcctSeedERP__Product__r.Family,
              GMBLASERP__Unit_Price__c,
              Insurance_Coverage__c,
              Insurance_Rate__c
            FROM AcctSeedERP__Materials__r
          )
        FROM AcctSeed__Project_Task__c
        WHERE AcctSeed__Project__c = :recordId AND IsInsurance__c = TRUE
      ];
    }
  }

  @AuraEnabled
  public static String fetchRecord(String recordId) {
    return JSON.serialize(new RecordWrapper(recordId));
  }

  @AuraEnabled
  public static void updateRecord(String financeDataJSON, Id recordId) {
    DataWrapper financeData = (DataWrapper) JSON.deserialize(financeDataJSON, DataWrapper.class);
    String objType = LGND_Utilities.sObjectNameFromId(recordId);
    if (objType == 'Opportunity')
      updateFinanceInfoOnOpp(financeData, recordId);
    if (objType == 'AcctSeed__Project__c')
      updateFinanceInfoOnERP(financeData, recordId);
  }

  private static void updateFinanceInfoOnOpp(DataWrapper financeData, Id recordId) {
    Opportunity opp = new Opportunity(
      Id = recordId,
      Deposit__c = financeData.deposit,
      Finance_Ammortization__c = financeData.finAmort,
      Finance_Annual_Interest__c = financeData.intrestRate,
      Finance_Term__c = financeData.finTerm,
      Insurance_Term__c = financeData.insTerm
    );
    update opp;
  }

  private static void updateFinanceInfoOnERP(DataWrapper financeData, Id recordId) {
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      Id = recordId,
      Deposit__c = financeData.deposit,
      Finance_Ammortization__c = financeData.finAmort,
      Finance_Annual_Interest__c = financeData.intrestRate,
      Finance_Term__c = financeData.finTerm,
      Insurance_Term__c = financeData.insTerm
    );
    update erp;
  }
}
