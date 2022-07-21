/* TODO: DELETE ME */
public with sharing class CasePart {
  //  public static Boolean disableTrigger{
  //    get{
  //      if(disableTrigger == null) return false;
  //      else return disableTrigger;
  //    }
  //    set{
  //      if(value == null) disableTrigger = false;
  //      else disableTrigger = value;
  //    }
  //  }
  //
  //  public static void triggerHandler
  //    (map<Id,Case_Part__c> oldMap,
  //     map<Id,Case_Part__c> newMap,
  //     list<Case_Part__c> listNew,
  //     Boolean boolIsBefore,
  //     Boolean boolIsInsert,
  //     Boolean boolIsUpdate,
  //     Boolean boolIsDelete)
  //  {
  //
  //    if(oldMap == NULL) oldMap = new map<Id,Case_Part__c>();
  //    if(newMap == NULL) newMap = new map<Id,Case_Part__c>();
  //    if(listNew == NULL) listNew = new list<Case_Part__c>();
  //
  //
  //    //Things to do BEFORE
  //    if(boolIsBefore) {
  //      if(boolIsInsert)
  //      {
  //
  //      }
  //    //if(boolIsUpdate)
  //    //{
  //    //  return;
  //    //}
  //      if(boolIsDelete)
  //      {
  //        AcctSeedERP__Material__c[] mats = [SELECT Id
  //                                           FROM AcctSeedERP__Material__c
  //                                           WHERE Case_Part__c IN :oldMap.keySet() ];
  //        delete mats;
  //      }
  //    }
  //    else // well.. if it is not before it has to be AFTER
  //    {
  //      if(boolIsInsert)
  //      {
  //        Map<Id, List<Case_Part__c>> caseMap = new Map<Id, List<Case_Part__c>>();
  //        for( Case_Part__c cp : listNew )
  //        {
  //          if( !caseMap.containsKey( cp.Case__c ) )
  //            caseMap.put( cp.Case__c, new List<Case_Part__c>() );
  //          caseMap.get( cp.Case__c ).add( cp );
  //        }
  //        Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, Warranty_Erp__c, Recoverable_Erp__c
  //                                                 FROM Case
  //                                                 WHERE Id IN :caseMap.keySet()
  //                                                 AND Warranty_Erp__c <> null ]);
  //        Set<Id> erpIds = new Set<Id>();
  //        for(Case c : cases.values() )
  //        {
  //          erpIds.add( c.Warranty_ERP__c );
  //          if( c.Recoverable_ERP__c != null )
  //            erpIds.add( c.Recoverable_ERP__c );
  //        }
  //        Map<Id, Id> erp_task_map = new Map<Id, Id>();
  //        for( AcctSeed__Project_Task__c pt : [SELECT Id, AcctSeed__Project__c
  //                                             FROM AcctSeed__Project_Task__c
  //                                             WHERE AcctSeed__Project__c IN :erpIds ] )
  //        {
  //          if( !erp_task_map.containsKey( pt.AcctSeed__Project__c ) )
  //            erp_task_map.put( pt.AcctSeed__Project__c, pt.Id );
  //        }
  //        List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
  //        for( Case c : cases.values() )
  //        {
  //          //Warranty ERP
  //          Id taskId = erp_task_map.get( c.Warranty_ERP__c );
  //          for( Case_Part__c cp : caseMap.get( c.Id) )
  //          {
  //            mats.add(  new AcctSeedERP__Material__c(
  //                AcctSeedERP__Product__c = cp.Product__c,
  //                AcctSeedERP__Quantity_Per_Unit__c = cp.Quantity__c,
  //                AcctSeedERP__Project__c = c.Warranty_ERP__c,
  //                AcctSeedERP__Project_Task__c = taskId,
  //                GMBLASERP__Unit_Price__c = cp.Unit_Price__c,
  //                Case_Part__c = cp.Id,
  //                No_WIP__c = cp.Inventory_Product__c
  //              )
  //            );
  //            if( c.Recoverable_ERP__c != null )
  //            {
  //              Id taskId2 = erp_task_map.get( c.Recoverable_ERP__c );
  //              mats.add(  new AcctSeedERP__Material__c(
  //                  AcctSeedERP__Product__c = cp.Product__c,
  //                  AcctSeedERP__Quantity_Per_Unit__c = cp.Quantity__c,
  //                  AcctSeedERP__Project__c = c.Recoverable_ERP__c,
  //                  AcctSeedERP__Project_Task__c = taskId2,
  //                  GMBLASERP__Unit_Price__c = cp.Unit_Price__c,
  //                  Case_Part__c = cp.Id,
  //                  No_WIP__c = cp.Inventory_Product__c
  //                )
  //              );
  //            }
  //          }
  //        }
  //        insert mats;
  //      }
  //      //if(boolIsUpdate)
  //      //{
  //      //}
  //      //if(boolIsDelete)
  //      //{
  //
  //      //}
  //    }
  //
  //  }
}
