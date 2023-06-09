/**
 * Created by dave on 2019-08-29.
 */

public with sharing class Material_Selector extends Application_Selector {
  public Material_Selector() {
    this.sObjectName = 'AcctSeedERP__Material__c';
    this.fields = new List<String>{
      'Id',
      'Material__c',
      'AcctSeedERP__Project__c',
      'AcctSeedERP__Project_Task__c',
      'AcctSeedERP__Project_Task__r.Name',
      'AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c',
      'AcctSeedERP__Product__c',
      'AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c',
      'AcctSeedERP__Product__r.RecordTypeId',
      'AcctSeedERP__Product__r.Family',
      'AcctSeedERP__Product__r.Name',
      'AcctSeedERP__Product__r.Is_Residual_Insurance__c',
      'AcctSeedERP__Quantity_Per_Unit__c',
      'AcctSeedERP__Quantity_Allocated__c',
      'AcctSeedERP__Comment__c',
      'GMBLASERP__Unit_Price__c',
      'GMBLASERP__Price_Override__c',
      'Parent_Product__c',
      'Insurance_Coverage__c',
      'Insurance_Rate__c'
    };
  }

  public static List<AcctSeedERP__Material__c> allFlexibleAccessoryCreditLinesByProjectIds(Set<Id> projectIds) {
    String ACCESSORY_CREDIT_PRODUCTID = Application_Constants.getInstance()
      .utilityProducts.getFlexibleAccessoriesCredit();
    List<String> additionalFields = new List<String>{
      'AcctSeedERP__Project__r.Name',
      'AcctSeedERP__Project__r.Boat_Specialist__c',
      'AcctSeedERP__Project__r.AcctSeed__Account__c',
      'AcctSeedERP__Project__r.AcctSeed__Account__r.Name',
      'AcctSeedERP__Project__r.Salesperson__c',
      'AcctSeedERP__Project__r.Serial_Number__c',
      'AcctSeedERP__Project__r.GMBLASERP__Warehouse__c',
      'AcctSeedERP__Project__r.GL_Account_Variable_1__c',
      'AcctSeedERP__Project__r.GL_Account_Variable_2__c',
      'AcctSeedERP__Project__r.GL_Account_Variable_3__c',
      'AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c'
    };
    return new Material_Selector()
      .addFields(additionalFields)
      .addWhereIdInField(projectIds, 'AcctSeedERP__Project__c')
      .addWhere('AcctSeedERP__Product__c = \'' + ACCESSORY_CREDIT_PRODUCTID + '\'')
      .query();
  }

  public static List<AcctSeedERP__Material__c> selectAllByTaskId(Set<Id> taskIds) {
    return new Material_Selector().addWhereIdInField(taskIds, 'AcctSeedERP__Project_Task__c').query();
  }

  public static List<AcctSeedERP__Material__c> allByProjectId(String projectId) {
    return new Material_Selector().addWhere('AcctSeedERP__Project__c = \'' + projectId + '\'').query();
  }

  public static List<AcctSeedERP__Material__c> allInsuranceMaterialsByProjectIds(Set<Id> projectIds) {
    String insuranceRt = String.valueOf(LGND_Constants.productRtId_Insurance);
    return new Material_Selector()
      .addWhereIdInField(projectIds, 'AcctSeedERP__Project__c')
      .addWhere('AcctSeedERP__Product__r.RecordTypeId = \'' + insuranceRt + '\'')
      .addWhere('Insurance_Rate__c <> null')
      .query();
  }

  public static List<AcctSeedERP__Material__c> allPartMaterialsByProjectIds(Set<Id> projectIds) {
    String partRt = String.valueOf(LGND_Constants.productRtId_Part);
    return new Material_Selector()
      .addWhereIdInField(projectIds, 'AcctSeedERP__Project__c')
      .addWhere('AcctSeedERP__Product__r.RecordTypeId = \'' + partRt + '\'')
      .query();
  }

  public static List<AcctSeedERP__Material__c> selectAllByIds(Set<Id> matIds) {
    Material_Selector selector = new Material_Selector();
    selector.addWhereIdIn(matIds);
    return selector.query();
  }

  public static Map<Id, AcctSeedERP__Material__c> mapAllByIds(Set<Id> matIds) {
    return new Map<Id, AcctSeedERP__Material__c>(Material_Selector.selectAllByIds(matIds));
  }

  public static List<AcctSeedERP__Material__c> allByCasePartIds(Set<id> casePartIds) {
    return new Material_Selector().addWhereIdInField(casePartIds, 'Case_Part__c').query();
  }
}
