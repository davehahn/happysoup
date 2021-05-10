public with sharing class LGND_Lead {

//  public static void doHandle( Map<Id,Lead> oldMap,
//                               Map<Id,Lead> newMap,
//                               List<Lead> listNew,
//                               Boolean boolIsBefore,
//                               Boolean boolIsInsert,
//                               Boolean boolIsUpdate,
//                               Boolean boolIsDelete )
//  {
//    if(oldMap == NULL) oldMap = new Map<Id,Lead>();
//    if(newMap == NULL) newMap = new Map<Id,Lead>();
//    if(listNew == NULL) listNew = new List<Lead>();
//
//    //Things to do BEFORE
//    if( boolIsBefore )
//    {
//      if( boolIsInsert )
//      {
//        preProcessLeadsFromAppSite( listNew );
//        for( Integer i=0; i < listNew.size(); i++ )
//        {
//          Lead l = listNew[i];
//          if( l.isPersonAccount__c == true )
//          {
//            l.Company = null;
//          }
//        }
//      }
//      if( boolIsUpdate )
//      {
//
//      }
//
//    }
//    //Things to do AFTER
//    else
//    {
//      if( boolIsInsert )
//      {
//        convertOrDeleteRequired( listNew );
//      }
//      if( boolIsUpdate )
//      {
//        convertOrDeleteRequired( listNew );
//      }
//      if( boolIsDelete )
//      {
//      }
//    }
//
//  }
//
//  private static void preProcessLeadsFromAppSite( List<Lead> listNew )
//  {
//    // get a list of submitted email addresses ONLY IF LeadSource = 'Purchased at Dealer'
//    Set<String> emails = new Set<String>();
//    for( Lead l : listNew )
//    {
//      if( l.LeadSource == 'Purchased at Dealer' )
//        emails.add( l.Email );
//    }
//    // look for any leads with these email address and make a Map of email address => Lead
//    Map<String, Lead> existingLeadsMap = new Map<String, Lead>();
//    Set<Id> existingLeadsToConvert = new Set<Id>();
//    for( Lead l : [SELECT Id, Email FROM Lead WHERE Email IN :emails] )
//    {
//      existingLeadsMap.put(l.Email, l);
//    }
//    System.debug('&&& existingLeadMaps &&& ' + existingLeadsMap );
//    // set deleteNow flag so the after insert trigger will delete it
//    for( Lead l : listNew )
//    {
//      if( existingLeadsMap.containsKey( l.Email ) )
//      {
//        l.deleteNow__c = true;
//        existingLeadsToConvert.add( existingLeadsMap.get( l.Email ).Id );
//      }
//      else
//      {
//        if( l.LeadSource == 'Purchased at Dealer' )
//          l.convertNow__c = true;
//      }
//    }
//    System.debug('&&& existingLeadsToConvert &&& ' + existingLeadsToConvert );
//    if( !existingLeadsToConvert.isEmpty() )
//      updateExistingLeadsToConvert( existingLeadsToConvert );
//  }
//
//  private static void convertOrDeleteRequired( List<Lead> listNew )
//  {
//    LeadStatus convertStatus = [
//          select MasterLabel
//          from LeadStatus
//          where IsConverted = true
//          limit 1
//     ];
//     List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
//     Set<Id> toDelete = new Set<Id>();
//
//    for (Lead lead: listNew) {
//      //check if this lead need converting
//      if (!lead.isConverted && lead.convertNow__c == true)
//      {
//        Database.LeadConvert lc = new Database.LeadConvert();
//        lc.setLeadId(lead.Id);
//        lc.setDoNotCreateOpportunity( true );
//        lc.setConvertedStatus(convertStatus.MasterLabel);
//        leadConverts.add(lc);
//      }
//      //check if lead should be deleted
//      if( lead.deleteNow__c == true )
//        toDelete.add( lead.Id );
//    }
//
//    if( !leadConverts.isEmpty() )
//      List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
//    if( !toDelete.isEmpty() )
//      deleteLeads( toDelete );
//
//  }
//
//  //@future
//  private static void updateExistingLeadsToConvert( Set<Id> leadIds )
//  {
//    Lead[] ls = [SELECT Id FROM Lead WHERE Id IN :leadIds ];
//    for( Lead l : ls )
//    {
//      l.convertNow__c = true;
//    }
//    update ls;
//  }
//
//  //@future
//  private static void deleteLeads( Set<Id> leadIds )
//  {
//    Lead[] lds = [SELECT Id FROM Lead WHERE Id IN :leadIds];
//    delete lds;
//  }


}