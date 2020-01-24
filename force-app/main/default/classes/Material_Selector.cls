/**
 * Created by dave on 2019-08-29.
 */

public with sharing class Material_Selector {

  public static List<AcctSeedERP__Material__c> selectAllByTaskId( Set<Id> taskIds )
  {
    return [ SELECT Id,
      AcctSeedERP__Project_Task__c,
      AcctSeedERP__Product__c,
      AcctSeedERP__Quantity_Per_Unit__c
    FROM AcctSeedERP__Material__c
    WHERE AcctSeedERP__Project_Task__c In :taskIds ];

  }

  public static List<AcctSeedERP__Material__c> selectAllByIds( Set<Id> matIds )
  {
    return [ SELECT Id,
                    AcctSeedERP__Project_Task__c,
                    AcctSeedERP__Product__c,
                    AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
                    AcctSeedERP__Product__r.RecordTypeId,
                    AcctSeedERP__Product__r.Family,
                    AcctSeedERP__Quantity_Per_Unit__c,
                    AcctSeedERP__Comment__c,
                    GMBLASERP__Unit_Price__c
             FROM AcctSeedERP__Material__c
             WHERE Id IN :matIds];
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