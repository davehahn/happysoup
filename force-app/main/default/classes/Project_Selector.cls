/**
 * Created by dave on 2020-01-15.
 */

public with sharing class Project_Selector
{
  public static Map<Id, AcctSeed__Project__c> mapAllById(Set<Id> ids)
  {
    return new Map<Id, AcctSeed__Project__c>([
      SELECT Id,
        AcctSeed__Status__c,
        Stage__c
      FROM AcctSeed__Project__c
      WHERE Id IN :ids
    ]);
  }
}
