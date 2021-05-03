public with sharing class OpportunityDetailExt {

  private User currentUser;
  private ApexPages.StandardController stdCtrl;
  private Opportunity opp;
  //private CommissionRecord__c[] comRecords;
  public Product2 boat { get; private set; }


	public OpportunityDetailExt(ApexPages.StandardController std) {
    stdCtrl = std;
    opp = getOurOpp();
    currentUser = [SELECT Id, Name, Profile.Name
                   FROM User
                   WHERE Id = :UserInfo.getUserId()];
    //comRecords = [SELECT Id,
    //                    (SELECT Id FROM CommissionPayments__r WHERE Owner__c = :currentUser.Id)
    //              FROM CommissionRecord__c
    //              WHERE OpportunityId__c = :opp.Id];
    boat = findBoat();
	}


  //public Boolean getHasCommission()
  //{
  //  Set<String> allowedProfiles = new Set<String>{'System Administrator', 'Sales and Operations Manager', 'Legend Admin'};
  //  return ( getHasLineItems() &&
  //   ( ( allowedProfiles.contains(currentUser.Profile.Name) && opp.Probability > 0 )
  //    || ( comRecords.size() > 0 && userHasCommissionPayment() ) )
  //  ) ;
  //}

  public Boolean getHasLineItems()
  {
    return opp.Line_Item_Count__c > 0;
  }

  public String getFormattedDeliveryDate()
  {
    if( opp.Delivery_Date__c == null )
    {
      return 'Not Set';
    }
    return opp.Delivery_Date__c.format('MMM d, yyyy @ h:mm a');
  }


  @RemoteAction
  public static Opportunity updateStage(String OppId, String newStage){
    String stageToSet;
    Opportunity o = [SELECT Id, StageName, Probability FROM Opportunity WHERE Id = :oppId];
    if( o.StageName == newStage ){
      Map<String, String> stageRollbackMap = new Map<String,String>{
        'Orientation Specialist Add-On Call' => 'Tagging Pending',
        'Pending Work Order' => 'Orientation Specialist Add-On Call',
        'Pending Rigging' => 'Pending Work Order',
        'Pending Inspection' => 'Pending Rigging',
        'Pending Pickup' => 'Pending Inspection',
        'Picked Up / Won' => 'Pending Pickup'
      };
      stageToSet = stageRollbackMap.get(newStage);
    } else {
      Set<String> stages = new Set<String>();
      Schema.DescribeFieldResult opportunityStageName = Opportunity.StageName.getDescribe();
      for( Schema.PickListEntry ple : opportunityStageName.getPicklistValues() ){
        stages.add( ple.getLabel() );
      }
      if( stages.contains(newStage) ){
        stageToSet = newStage;
      }
    }

    if( stageToSet != null ){
      Map<String, Decimal> probabilityStageNameMap = new Map<String, Decimal>();
      for (OpportunityStage oppStage : [Select MasterLabel, DefaultProbability
                                        From OpportunityStage]) {
        probabilityStageNameMap.put(oppStage.MasterLabel, oppStage.DefaultProbability);
      }
      o.Probability = probabilityStageNameMap.get(stageToSet);
      o.StageName = stageToSet;
      update o;
      return o;
    } else {
      return null;
    }

  }

  private Opportunity getOurOpp()
  {
    if( Test.isRunningTest() )
    {
      return [SELECT Id, Name, BoatId__c, Line_Item_Count__c, Probability, StageName, Delivery_Date__c
              FROM Opportunity
              WHERE Id = :stdCtrl.getId() ];
    }
    else
    {
      stdCtrl.addFields( new List<String>{'BoatId__c', 'Line_Item_Count__c', 'Delivery_Date__c'} );
      return (Opportunity)stdCtrl.getRecord();
    }
  }

  //private Boolean userHasCommissionPayment()
  //{
  //  Boolean result = false;
  //  for(CommissionRecord__c cr : comRecords)
  //  {
  //    if( cr.CommissionPayments__r.size() > 0 )
  //    {
  //      result = true;
  //    }
  //  }
  //  return result;
  //}

  private Product2 findBoat()
  {
    try
    {
      return [SELECT Id, Name, Family FROM Product2 WHERE Id = :opp.BoatId__c];
    }
    catch(Exception e)
    {
      return null;
    }
  }


}