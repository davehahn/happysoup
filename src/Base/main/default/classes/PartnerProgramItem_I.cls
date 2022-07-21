/**
 * Created by dave on 2020-07-29.
 */

public interface PartnerProgramItem_I {
  Void init(PartnerProgram_Service.DealerOrderWrapper orderWrapper);
  Boolean isApplicable();
  Boolean wasAppliedPreviously();
  String getBookingOrderFieldName();
  Decimal getDiscountPercent();
  List<AcctSeedERP__Material__c> apply();
  List<AcctSeedERP__Material__c> revert();
  String getName();
  PartnerProgram_Service.ResultMessage getResult();
  PartnerProgram_Service.DealerOrderWrapper getOrderWrapper();
}
