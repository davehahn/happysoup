/**
 * Created by dave on 2019-08-29.
 */

public with sharing class Material_Selector extends Application_Selector {

  public Material_Selector()
  {
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
      'Insurance_Coverage__c',
      'Insurance_Rate__c'
    };
  }

  public static List<AcctSeedERP__Material__c> selectAllByTaskId( Set<Id> taskIds )
  {
    return [ SELECT Id,
      AcctSeedERP__Project_Task__c,
      AcctSeedERP__Product__c,
      AcctSeedERP__Quantity_Per_Unit__c
    FROM AcctSeedERP__Material__c
    WHERE AcctSeedERP__Project_Task__c In :taskIds ];
  }

  public static List<AcctSeedERP__Material__c> allByProjectId( String projectId )
  {
    return new Material_Selector()
      .addWhere( 'AcctSeedERP__Project__c = \'' + projectId + '\'' )
      .query();
  }

  public static List<AcctSeedERP__Material__c> allInsuranceMaterialsByProjectIds( Set<Id> projectIds )
  {
    String insuranceRt = String.valueOf( LGND_Constants.productRtId_Insurance );
    Material_Selector selector = new Material_Selector();
    selector
      .addWhereIdInField( projectIds, 'AcctSeedERP__Project__c' )
      .addWhere('AcctSeedERP__Product__r.RecordTypeId = \'' + insuranceRt + '\'' );
    return selector.query();
  }

  public static List<AcctSeedERP__Material__c> selectAllByIds( Set<Id> matIds )
  {
    Material_Selector selector = new Material_Selector();
    selector.addWhereIdIn( matIds );
    return selector.query();
  }

  public static Map<Id,AcctSeedERP__Material__c> mapAllByIds( Set<Id> matIds )
  {
    return new Map<Id,AcctSeedERP__Material__c>([ SELECT Id,
      AcctSeedERP__Project_Task__c,
      AcctSeedERP__Product__c,
      AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
      AcctSeedERP__Product__r.RecordTypeId,
      AcctSeedERP__Product__r.Family,
      AcctSeedERP__Quantity_Per_Unit__c,
      AcctSeedERP__Comment__c,
      GMBLASERP__Unit_Price__c
    FROM AcctSeedERP__Material__c
    WHERE Id IN :matIds]);
  }

}