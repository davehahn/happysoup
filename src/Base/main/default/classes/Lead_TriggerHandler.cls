/**
 * Created by dave on 2019-11-01.
 */

public without sharing class Lead_TriggerHandler extends TriggerHandler
{

  private static  List<Lead_Source_Assignment__mdt> leadSourceAssignments {
    get {
      if( leadSourceAssignments == null ){
        leadSourceAssignments = Lead_Source_Assignment__mdt.getAll().values();
      }
      return leadSourceAssignments;
    }
    set;
  }

  @TestVisible
  private static Map<String, String> factoryAccountIdByLeadSource {
    get {
      if( factoryAccountIdByLeadSource == null ){
        factoryAccountIdByLeadSource = new Map<String, String>();
        Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
        for( Lead_Source_Assignment__mdt assignment : leadSourceAssignments ){
          factoryAccountIdByLeadSource.put( assignment.Lead_Source__c, String.valueOf(settings.get( assignment.Custom_Settings_Name__c )) );
        }
      }
      return factoryAccountIdByLeadSource;
    }
    set;
  }

//  protected override void bulkBefore()
//  {
//  }

//  protected override void bulkAfter()
//  {
//  }

  protected override void beforeInsert()
  {
    /**
     * This is for Hubspot since it submits Leads with Company populated
     * to something like [none], which still counts as something so when we
     * use the default convert lead mechanism, it creates a Business Account
     * since the Company field is not null
     **/
    System.debug('Lead TriggerHandler - BEFORE INSERT');
    for( Lead l : (List<Lead>)Trigger.new )
    {
      if( l.isPersonAccount__c == true )
      {
        l.Company = null;
      }
    }
    setClosestByLeadSource( (List<Lead>)Trigger.new );
  }

  protected override void beforeUpdate()
  {
    setClosestByLeadSource( (List<Lead>)Trigger.new );
  }

//  protected override void beforeDelete()
//  {
//  }

  protected override void afterInsert()
  {
    shouldSetClosestPartner( (List<Lead>)Trigger.new, null );
  }

  protected override void afterUpdate()
  {
    shouldSetClosestPartner( (List<Lead>)Trigger.new, (Map<Id,Lead>)Trigger.oldMap );
  }

//  protected override void afterDelete()
//  {
//  }

//  protected override void afterUndelete()
//  {
//  }

//  protected override void finalActions()
//  {
//  }

  private static void setClosestByLeadSource( List<Lead> newList ){
    for( Lead l : newList ){
      if( factoryAccountIdByLeadSource.containsKey( l.LeadSource ) ){
        l.Closest_Partner__c = factoryAccountIdByLeadSource.get( l.LeadSource );
      }
    }
  }

  private static void shouldSetClosestPartner( List<Lead> listNew,
                                               Map<Id, Lead> oldMap )
  {
    Set<Id> setClosestPartner = new Set<Id>();
    for( Lead l : listNew )
    {
      //skip any records with a specific Lead Source found in Lead_Source_Assignment__mdt
      if( factoryAccountIdByLeadSource.containsKey( l.LeadSource ) ) continue;
      // during INSERT
      if( oldMap == null )
      {
        if( l.PostalCode != null ||
            l.IP_City__c != null ||
            l.hubspot_IP_City_Lead__c != null)
        {
          setClosestPartner.add(l.Id);
        }
      }
      // during UPDATE
      if( oldMap != null )
      {
        Lead oldLead = oldMap.get( l.Id );
        if( ( l.PostalCode != null && l.PostalCode != oldLead.PostalCode ) ||
            ( l.IP_City__c != null && l.IP_City__c != oldLead.IP_City__c ) ||
            ( l.hubspot_IP_City_Lead__c != null && l.hubspot_IP_City_Lead__c != oldLead.IP_City__c ) )
        {
          setClosestPartner.add(l.Id);
        }
      }
    }
    if( setClosestPartner.size() > 0 )
    {
      System.enqueueJob( new ClosestPartnerQueue( setClosestPartner ) );
    }
  }

  public class ClosestPartnerQueue implements Queueable, Database.AllowsCallouts {

    public final Set<Id> leadIds;

    public ClosestPartnerQueue( Set<Id> ids )
    {
      this.leadIds = ids;
    }

    public void execute( QueueableContext context )
    {
      String origin;
      PartnerLocator locator = new PartnerLocator();
      List<Lead> leads = [ SELECT Id,
                                  PostalCode,
                                  Ip_City__c,
                                  hubspot_IP_City_Lead__c
                          FROM Lead
                          WHERE Id IN :this.leadIds ];
      for( Lead l : leads )
      {

        origin = null;
        if( l.PostalCode != null )
          origin = l.PostalCode;
        else if( l.IP_City__c != null )
          origin = l.IP_City__c;
        else if( l.hubspot_IP_City_Lead__c != null )
          origin = l.hubspot_IP_City_Lead__c;
        if( origin != null )
        {
          PartnerLocator.SearchResult result = locator.execute( origin, 1 );
          if( result.mapMarkers.size() > 0 )
          {
            try {
              /** use this if we want to set the owner to a Partner User
                  This also sets the standard PartnerAccount field automatically
                  based on the Users Account.
                  NOTE:  In Unit test having to create a Test User cause the test to fail
                         complaining about uncommitted changes due to the Queueable.
                         this is a known issue from Salesforce, so don't forget
              **/
//              User pOwner = [SELECT Id FROM User WHERE AccountId = :result.mapMarkers[0].id ];
//              l.OwnerId = pOwner.Id;
              l.Closest_Partner__c = result.mapMarkers[0].id;
            }
            catch( Exception e )
            {
              System.debug( e.getMessage() );
            }
          }
        }
      }
      TriggerHandler.bypass('Lead_TriggerHandler');
      update leads;
      TriggerHandler.clearBypass('Lead_TriggerHandler');
    }
  }
}