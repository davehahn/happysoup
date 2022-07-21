/**
 * Created by Tim on 2021-04-30.
 */

public with sharing class CommSharedLeadForm_Controller {
  @AuraEnabled
  public static Lead insertLead(Lead l, String cid, Lead_Submission_History__c lsh) {
    System.debug('Lead string l: ' + l);
    System.debug('cid: ' + cid);
    Lead_Service service = new Lead_Service(l);
    Lead_Service.LeadSaveResult sr = service.insertOrUpdateDuplicate();

    if (sr.isSuccess()) {
      Lead newLead = sr.getRecord();
      try {
        addToHistory(newLead.Id, lsh);
      } catch (Exception e) {
        System.debug('addToHistory e:' + e);
      }
      if (cid != null) {
        try {
          addToCampaign(newLead.Id, cid);
        } catch (Exception e) {
          System.debug('addtocampaing e: ' + e);
        }
      }

      System.debug('sr: ' + sr);
    }

    return sr.getRecord();
  }

  public static void addToCampaign(String lid, String cid) {
    System.debug('AddLeadToCampaign');
    System.debug('Lead Id: ' + lid + ', Campaign Id: ' + cid);
    List<CampaignMember> members = CampaignMember_Selector.allByLeadAndCampaignId(lid, cid);
    if (members.size() == 0) {
      insert new CampaignMember(LeadId = lid, CampaignId = cid);
    }
  }

  public static void addToHistory(String lid, Lead_Submission_History__c lsh) {
    System.debug('addToHistory');
    System.debug('Lead Id: ' + lid + ', History Record: ' + lsh);

    lsh.Lead_ID__c = lid;
    insert lsh;
  }
}
