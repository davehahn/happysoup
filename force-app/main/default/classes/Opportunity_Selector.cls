/**
 * Created by dave on 2019-08-06.
 */

public with sharing class Opportunity_Selector {

  public static Opportunity[] selectAllByIdWithLineItems( Set<Id> oppIds )
  {
    return [ SELECT Id,
      Name,
      CampaignId,
      LeadSource,
      AccountId,
      Pricebook2Id,
      Trade_In_Amount__c,
      Trade_In_Value__c,
      Business_Manager__c,
      RecordType.Name,
      Warehouse__c,
      Deposit__c,
      Deposit_Method__c,
      On_Water_Orientation__c,
      Pickup_Location__c,
      Payment_Method__c,
      Finance_Status__c,
      Customer_Notes__c,
      Delivery_Date__c,
      ContactEmail__c,
      BoatId__c,
      GL_Account_Variable_3__c,
      OwnerId,
      Insurance_Term__c,
      Finance_Term__c,
      Finance_Annual_Interest__c,
      Finance_Ammortization__c,
      Finance_Payments_Per_Year__c,
      Finance_Compound__c,
      Tax_Override__c,
      Tax_Rate_Federal__c,
      Tax_Rate_Provincial__c,
      Tax_Rate_Retail__c,
      Boat_Specialist_Id__c,
      Boat_Model_Year__c,
      Trailer_Model_Year__c,
      (SELECT Id,
              Description,
              ListPrice,
              Product2Id,
              ParentProductId__c,
              Product2.RecordTypeId,
              Product2.Family,
              Quantity,
              InsuranceCoverage__c,
              Insurance_Rate__c,
              UnitPrice
      FROM OpportunityLineItems)
    FROM Opportunity
    WHERE Id = :oppIds
    ];
  }

}
