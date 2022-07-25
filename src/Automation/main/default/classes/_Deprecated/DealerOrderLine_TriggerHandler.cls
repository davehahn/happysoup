/**
 * Created by dave on 2020-11-24.
 */
/* TODO: DELETE ME */
public without sharing class DealerOrderLine_TriggerHandler extends TriggerHandler {
  //
  //  public static Boolean disablePartnerProgram {
  //    get{
  //      if(disablePartnerProgram == null) return false;
  //      else return disablePartnerProgram;
  //    }
  //    set;
  //  }
  //
  //  protected override void bulkBefore()
  //  {
  //  }
  //
  //  protected override void bulkAfter()
  //  {
  //  }
  //
  //  protected override void beforeInsert()
  //  {
  //    setLineTotal( (List<Dealer_Order_Line__c>)Trigger.new);
  //  }
  //
  //  protected override void beforeUpdate()
  //  {
  //    setLineTotal( (List<Dealer_Order_Line__c>)Trigger.new);
  //  }
  //
  //  protected override void beforeDelete()
  //  {
  //    for( Dealer_Order_Line__c dol : (List<Dealer_Order_Line__c>)Trigger.old )
  //    {
  //      if( dol.Reserved_For_Customer_Id__c != null )
  //      {
  //        String err = 'You can not delete the line. It is currently reserved for a customer';
  //        dol.addError( err );
  //      }
  //    }
  //  }
  //
  //  protected override void afterInsert()
  //  {
  //    handlePartnerProgram( (List<Dealer_Order_Line__c>)Trigger.new);
  //  }
  //
  //  protected override void afterUpdate()
  //  {
  //    handlePartnerProgram( (List<Dealer_Order_Line__c>)Trigger.new);
  //  }
  //
  //  protected override void afterDelete()
  //  {
  //    Set<Id> erpIds = new Set<Id>();
  //    Set<Id> transferIds = new Set<Id>();
  //    Set<Id> motorRequestIds = new Set<Id>();
  //    Set<Id> dealerOrderIds = new Set<Id>();
  //    List<Dealer_Order_Line__c> dols = (List<Dealer_Order_Line__c>)Trigger.oldMap.values();
  //
  //    for( Dealer_Order_Line__c dol : dols )
  //    {
  //      if( dol.ERP_Order__c != null )
  //      {
  //        erpIds.add(dol.ERP_Order__c);
  //        dealerOrderIds.add( dol.Dealer_Order__c );
  //      }
  //      if( dol.Legend_Transfer_Request__c != null )
  //        transferIds.add( dol.Legend_Transfer_Request__c );
  //      if( dol.Dealer_Motor_Request__c != null )
  //        motorRequestIds.add( dol.Dealer_Motor_Request__c );
  //    }
  //    if( erpIds.size() > 0 )
  //    {
  //      TriggerBase.bypass('Dealer_Order__c');
  //      deleteErps(erpIds);
  //      TriggerBase.clearBypass('Dealer_Order__c');
  ////          PartnerProgram_Service ppService = new PartnerProgram_Service( dealerOrderIds );
  ////          ppService.checkAndApply();
  //    }
  //    if( transferIds.size() > 0 )
  //      deleteLegendTransferRequests( transferIds );
  //    if( motorRequestIds.size() > 0 )
  //      deleteDealerMotorRequests( motorRequestIds );
  //    handlePartnerProgram( dols );
  //  }
  //
  //  protected override void afterUndelete()
  //  {
  //  }
  //
  //  protected override void finalActions()
  //  {
  //  }
  //
  //  /*
  //  .______   .______       __  ____    ____  ___   .___________. _______
  //  |   _  \  |   _  \     |  | \   \  /   / /   \  |           ||   ____|
  //  |  |_)  | |  |_)  |    |  |  \   \/   / /  ^  \ `---|  |----`|  |__
  //  |   ___/  |      /     |  |   \      / /  /_\  \    |  |     |   __|
  //  |  |      |  |\  \----.|  |    \    / /  _____  \   |  |     |  |____
  //  | _|      | _| `._____||__|     \__/ /__/     \__\  |__|     |_______|
  //   */
  //
  //  private static void setLineTotal( List<Dealer_Order_Line__c> lines )
  //  {
  //    for( Dealer_Order_Line__c dol : lines )
  //    {
  //      dol.Line_Total__c = dol.Line_Total_Pre_Tax__c;
  //      dol.Line_Total_No_Fees_or_Discounts__c = dol.Line_Total_NoFeesOrDiscountsCalc__c;
  //    }
  //  }
  //
  //  private static void handlePartnerProgram( List<Dealer_Order_Line__c> listNew )
  //  {
  //    if( disablePartnerProgram ) return;
  //
  //    Set<Id> dealerOrderIds = new Set<Id>();
  //    for( Dealer_Order_Line__c dol : listNew )
  //    {
  //      if( dol.ERP_Order__c != null && !dol.Is_For_Factory_Store__c )
  //      {
  //        dealerOrderIds.add( dol.Dealer_Order__c );
  //      }
  //    }
  //    applyPartnerProgram( dealerOrderIds );
  //  }
  //
  //  @Future
  //  public static void applyPartnerProgram( Set<Id> dealerOrderIds )
  //  {
  //    Map<Id, Dealer_Order__c> dealerOrders = new Map<Id, Dealer_Order__c>(
  //    [SELECT Id FROM Dealer_Order__c WHERE Id IN :dealerOrderIds AND Is_Booking_Order__c = true]
  //    );
  //    PartnerProgram_Service ppService = new PartnerProgram_Service( dealerOrders.keySet() );
  //    ppService.checkAndApply();
  //  }
  //
  //  public static void deleteErps( Set<Id> erpIds )
  //  {
  //    delete [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c IN:erpIds];
  //    delete [SELECT Id FROM AcctSeed__Project__c WHERE Id IN :erpIds];
  //  }
  //
  //  private static void deleteLegendTransferRequests( Set<Id> transferIds )
  //  {
  //    Legend_Transfer_Request__c[] ltrs = [SELECT Id
  //    FROM Legend_Transfer_Request__c
  //    WHERE Id IN :transferIds];
  //    delete ltrs;
  //  }
  //
  //  private static void deleteDealerMotorRequests( Set<Id> motorRequestIds )
  //  {
  //    Dealer_Motor_Request__c[] dmrs = [SELECT Id
  //    FROM Dealer_Motor_Request__c
  //    WHERE Id IN :motorRequestIds];
  //    delete dmrs;
  //  }
}
