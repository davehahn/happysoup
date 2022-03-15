/**
 * Created by dave on 2020-05-13.
 */

public without sharing class Lead_Selector extends Application_Selector
{

  public Lead_Selector()
  {
    this.sObjectName = 'Lead';
    this.fields = new List<String>
    {
      'Id',
      'CreatedDate',
      'FirstName',
      'LastName',
      'Phone',
      'MobilePhone',
      'Email',
      'LeadSource',
      'Company',
      'IsConverted',
      'Street',
      'City',
      'State',
      'StateCode',
      'Country',
      'CountryCode',
      'PostalCode',
      'Preferred_Language__c',
      'hubspot_plan_to_purchase__c',
      'hubspot_Boat_Type__c',
      'BoatModel__c',
      'hubspot_subscribe_legend_newsletter__c',
      'Marketing_Cloud_Notes__c',
      'Lead_Notification_Pending__c'
    };
  }

  public static List<Lead> allByIds( Set<Id> ids )
  {
    return new Lead_Selector()
      .addWhereIdIn( ids )
      .query();
  }

  public static Lead byIdIncludingCampaignMembers( Id recordId )
  {
    Lead_Selector selector = new Lead_Selector();
    selector.addWhereIdIn( new Set<Id>{ recordId } )
      .addChildQuery(
      '(SELECT Id, CampaignId, Campaign.Name FROM CampaignMembers)'
    );
    List<SObject> result = selector.query();
    if( result.size() == 0 )
    {
      throw new Application_Selector.SelectorException(
        'No Lead record found with supplied Id'
      );
    }
    else
    {
      return (Lead)result[0];
    }
  }

  public static List<Lead> allNonConvertedByEmail( String email )
  {
    Lead_Selector selector = new Lead_Selector();
    selector
      .addWhere('IsConverted = false')
      .addWhere( 'Email = \'' + email +'\'', 'AND' )
      .addOrderBy( 'CreatedDate DESC' );
    return (List<Lead>)selector.query();
  }
}