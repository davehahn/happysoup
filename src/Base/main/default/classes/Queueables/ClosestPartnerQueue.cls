/**
 * Created by dave on 2022-06-15.
 */

public class ClosestPartnerQueue implements Queueable, Database.AllowsCallouts {
  public final Set<Id> leadIds;

  public ClosestPartnerQueue(Set<Id> ids) {
    this.leadIds = ids;
  }

  public void execute(QueueableContext context) {
    String origin;
    PartnerLocator locator = new PartnerLocator();
    List<Lead> reassign = new List<Lead>();
    List<Lead> dontReassign = new List<Lead>();
    for (Lead l : Lead_Selector.allByIds(this.leadIds)) {
      if (Lead_Service.setClosestPartnerByLeadSource(l))
        continue;
      origin = null;
      if (l.PostalCode != null) {
        origin = l.PostalCode;
      } else if (l.IP_City__c != null) {
        origin = l.IP_City__c;
      } else if (l.hubspot_IP_City_Lead__c != null) {
        origin = l.hubspot_IP_City_Lead__c;
      }
      if (origin != null) {
        PartnerLocator.SearchResult result = locator.execute(origin, 1, l.BoatModel__r.Family);
        if (result.mapMarkers.size() > 0) {
          try {
            /** use this if we want to set the owner to a Partner User
                This also sets the standard PartnerAccount field automatically
                based on the Users Account.
                NOTE:  In Unit test having to create a Test User cause the test to fail
                       complaining about uncommitted changes due to the Queueable.
                       this is a known issue from Salesforce, so don't forget
            **/
            l.Closest_Partner__c = result.mapMarkers[0].id;
          } catch (Exception e) {
            System.debug(e.getMessage());
          }
        }
      }
      if (l.Status == Lead_Service.NEW_STATUS) {
        reassign.add(l);
      } else {
        dontReassign.add(l);
      }
    }
    TriggerBase.bypass('Lead');
    Database.DMLOptions options = new Database.DMLOptions();
    options.emailHeader.triggerUserEmail = true;
    options.assignmentRuleHeader.useDefaultRule = true;
    Database.update(reassign, options);
    options.emailHeader.triggerUserEmail = false;
    options.assignmentRuleHeader.useDefaultRule = false;
    Database.update(dontReassign, options);
    TriggerBase.clearBypass('Lead');
  }
}
