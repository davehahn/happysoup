/**
 * Created by dave on 2019-11-14.
 */

public inherited sharing class Project_Service
{

  public class Project {

    public AcctSeed__Project__c record;
    public Opportunity opportunity;

    private Application_RecordType.ERPOrderRTs recordTypes;

    public Project()
    {
      this.recordTypes = new Application_RecordType.ERPOrderRTs();
    }

    public AcctSeed__Project__c getRecord()
    {
      return this.record;
    }

    public Project newFromOpportunity( Opportunity opp )
    {
      this.opportunity = opp;
      buildRecordFromOpp();
      Application_RecordType.OpportunityRTs rts = new Application_RecordType.OpportunityRTs();
      if( this.opportunity.RecordTypeId == rts.getRetailId() )
      {
        configureForRetailBoatSale();
      }
      if( this.opportunity.RecordTypeId == rts.getOnlineId() )
      {
        if( this.opportunity.IsPickupDealershipPartner__c )
        {
          configureForPartnerRetailBoatSale();
        }
        else
        {
          configureForRetailBoatSale();
        }
      }
      insert this.record;
      return this;
    }

    public Project newFromOpportunityId( Id oppId )
    {
      try
      {
        return newFromOpportunity(
          Opportunity_Selector.selectAllByIdWithLineItems( new Set<Id>{ oppId } )[0]
        );
      }
      catch( Exception e )
      {
        throw new Application_Selector.SelectorException( 'Opportunity not found, invalid Id supplied');
      }
    }

    private void configureForRetailBoatSale()
    {
      this.record.RecordTypeId = this.recordTypes.getRetailBoatSaleId();
      this.record.Stage__c = 'Tagging Pending';
    }

    private void configureForPartnerRetailBoatSale()
    {
      this.record.RecordTypeId = this.recordTypes.getPartnerRetailBoatSaleId();
      this.record.Stage__c = 'Tagging Pending';
    }

    private void buildRecordFromOpp()
    {
      this.record = new AcctSeed__Project__c(
        Name = (this.opportunity.Name).LEFT(80),
        Campaign__c = this.opportunity.CampaignId,
        LeadSource__c = this.opportunity.LeadSource,
        Deposit__c = this.opportunity.Deposit__c,
        Deposit_Method__c = this.opportunity.Deposit_Method__c,
        On_Water_Orientation__c = this.opportunity.On_Water_Orientation__c,
        Pickup_Location__c = this.opportunity.Pickup_Location__c,
        Delivery_Date__c = this.opportunity.Delivery_Date__c,
        AcctSeed__Account__c = this.opportunity.AccountId,
        AcctSeed__Opportunity__c = this.opportunity.Id,
        Boat_Product__c = this.opportunity.BoatId__c,
        GMBLASERP__Pricebook__c = this.opportunity.Pricebook2Id,
        Customer_Notes__c = this.opportunity.Customer_Notes__c,
        GMBLASERP__Warehouse__c = this.opportunity.Warehouse__c,
        GL_Account_Variable_3__c = this.opportunity.GL_Account_Variable_3__c,
        Business_Manager__c = this.opportunity.Business_Manager__c,
        Salesperson__c = this.opportunity.OwnerId,
        Payment_Method__c = this.opportunity.Payment_Method__c,
        Boat_Specialist__c = this.opportunity.Boat_Specialist_Id__c,
        Insurance_Term__c = this.opportunity.Insurance_Term__c,
        Finance_Term__c = this.opportunity.Finance_Term__c,
        Finance_Annual_Interest__c = this.opportunity.Finance_Annual_Interest__c,
        Finance_Ammortization__c = this.opportunity.Finance_Ammortization__c,
        Finance_Payments_Per_Year__c = this.opportunity.Finance_Payments_Per_Year__c,
        Finance_Compound_Per_Year__c = this.opportunity.Finance_Compound__c,
        Tax_Override__c = this.opportunity.Tax_Override__c,
        ContactEmail__c = this.opportunity.ContactEmail__c,
        BoatModelYear__c = this.opportunity.Boat_Model_Year__c,
        TrailerModelYear__c = this.opportunity.Trailer_Model_Year__c,
        Contract_Start_Date__c = this.opportunity.Contract_Start_Date__c,
        First_Payment_Date__c = this.opportunity.First_Payment_Date__c
      );
      if( this.opportunity.Tax_Override__c == true )
      {
        this.record.Tax_Rate_Federal__c = this.opportunity.Tax_Rate_Federal__c;
        this.record.Tax_Rate_Provincial__c = this.opportunity.Tax_Rate_Provincial__c;
        this.record.Tax_Rate_Retail__c = this.opportunity.Tax_Rate_Retail__c;
      }
      if( this.record.GMBLASERP__Warehouse__c == null )
      {
        this.record.GMBLASERP__Warehouse__c = Warehouse_Selector.selectDefaultWarehouseForUser().Id;
      }
    }
  }

  public static AcctSeed__Project__c newFromOpportunityId( Id oppId )
  {
    Opportunity opp = Opportunity_Selector.selectAllByIdWithLineItems( new Set<Id>{ oppId } )[0];

    Project project = new Project().newFromOpportunity( opp );

    Map<String, AcctSeed__Project_Task__c> projectTasks =
      ProjectTask_Service.insertDefaultTasks( project.getRecord() );
    List<AcctSeedERP__Material__c> materials = new list<AcctSeedERP__Material__c>();
    Material_Service.Material_Builder matBuilder =
      new Material_Service.Material_Builder(
        project.getRecord().Id,
        projectTasks.get('Sale').Id,
        projectTasks.get('Business Office').Id );

    for(OpportunityLineItem oli : opp.OpportunityLineItems )
    {
      materials.add( matBuilder.buildFromOppLineItem( oli ) );
    }
    /// Add material lines for Trade In
    materials.addAll( Material_Service.buildTradeInMaterialsFromOpportunity(
      opp,
      project.getRecord().Id,
      projectTasks.get('Sale').Id )
    );

    insert materials;

    opp.StageName = 'Sent to ERP';
    Boolean oldOppyTriggerVal = OpportunityTriggerHandler.disableTrigger;
    OpportunityTriggerHandler.disableTrigger = true;
    update opp;
    OpportunityTriggerHandler.disableTrigger = oldOppyTriggerVal;
    /// Lock the task now
    AcctSeed__Project_Task__c salesTask =  [SELECT Id, Name FROM AcctSeed__Project_Task__c WHERE Id = :projectTasks.get('Sale').Id ];
    salesTask.Locked__c = true;
    Boolean oldTaskVal = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    update salesTask;
    gcProjectTask.disableTrigger = oldTaskVal;
    return project.getRecord();
  }

//  public static AcctSeed__Project__c constructFromOpportunity( Opportunity opp )
//  {
//    Id projectRT = opp.RecordType.Name == 'Retail Counter Sale' ?
//      gcConstants.idRtProjectCounterSale :
//      gcConstants.idRtProjectBoatSale;
//    AcctSeed__Project__c result = new AcctSeed__Project__c(
//      Name = (opp.Name).LEFT(80),
//      Campaign__c = opp.CampaignId,
//      LeadSource__c = opp.LeadSource,
//      Stage__c = 'Tagging Pending',
//      Deposit__c = opp.Deposit__c,
//      Deposit_Method__c = opp.Deposit_Method__c,
//      On_Water_Orientation__c = opp.On_Water_Orientation__c,
//      Pickup_Location__c = opp.Pickup_Location__c,
//      Delivery_Date__c = opp.Delivery_Date__c,
//      AcctSeed__Account__c = opp.AccountId,
//      AcctSeed__Opportunity__c = opp.Id,
//      Boat_Product__c = opp.BoatId__c,
//      GMBLASERP__Pricebook__c = opp.Pricebook2Id,
//      RecordTypeId = projectRT,
//      Customer_Notes__c = opp.Customer_Notes__c,
//      GMBLASERP__Warehouse__c = opp.Warehouse__c,
//      GL_Account_Variable_3__c = opp.GL_Account_Variable_3__c,
//      Business_Manager__c = opp.Business_Manager__c,
//      Salesperson__c = opp.OwnerId,
//      Payment_Method__c = opp.Payment_Method__c,
//      Boat_Specialist__c = opp.Boat_Specialist_Id__c,
//      Insurance_Term__c = opp.Insurance_Term__c,
//      Finance_Term__c = opp.Finance_Term__c,
//      Finance_Annual_Interest__c = opp.Finance_Annual_Interest__c,
//      Finance_Ammortization__c = opp.Finance_Ammortization__c,
//      Finance_Payments_Per_Year__c = opp.Finance_Payments_Per_Year__c,
//      Finance_Compound_Per_Year__c = opp.Finance_Compound__c,
//      Tax_Override__c = opp.Tax_Override__c,
//      ContactEmail__c = opp.ContactEmail__c,
//      BoatModelYear__c = opp.Boat_Model_Year__c,
//      TrailerModelYear__c = opp.Trailer_Model_Year__c
//    );
//    if( opp.Tax_Override__c == true )
//    {
//      result.Tax_Rate_Federal__c = opp.Tax_Rate_Federal__c;
//      result.Tax_Rate_Provincial__c = opp.Tax_Rate_Provincial__c;
//      result.Tax_Rate_Retail__c = opp.Tax_Rate_Retail__c;
//    }
//    return result;
//  }

  public static List<Case> insertWarrantyPayablesFromCases( List<Case> cases )
  {
    Map<Id, Account> accountMap = buildAccountMap( cases );
    Map<String, Case> caseMap = new Map<String, Case>();
    Map<String, AcctSeed__Project__c> projectMap = new Map<String, AcctSeed__Project__c>();

    for( Case c : cases )
    {
      String id = LGND_Utilities.generateRandomString(6);
      caseMap.put( id, c );
      String accountName = accountMap.containsKey( c.AccountId ) ?
        accountMap.get( c.AccountId ).Name :
        '';
      projectMap.put( id, buildWarrantyPayableFromCase( c, accountName ) );
    }
    insert projectMap.values();

    ProjectTask_Service.insertWarrantyPayableTasksForProjects( projectMap.values() );

    for( String key : caseMap.keySet() )
    {
      caseMap.get( key ).Warranty_ERP__c = projectMap.get( key ).Id;
    }
    return caseMap.values();
  }

  public static AcctSeed__Project__c buildWarrantyPayableFromCase( Case c, String accountName )
  {
    return new AcctSeed__Project__c (
      Name =  accountName.trim(),
      RecordTypeId = gcConstants.idRtProjectWarranty,
      AcctSeed__Account__c = c.AccountId,
      Serial_Number__c = c.Serial_Number__c,
      GMBLASERP__Pricebook__c = c.Price_Book__c
    );
  }

  /**
      ____  ____  _____     ___  _____ _____
     |  _ \|  _ \|_ _\ \   / / \|_   _| ____|
     | |_) | |_) || | \ \ / / _ \ | | |  _|
     |  __/|  _ < | |  \ V / ___ \| | | |___
     |_|   |_| \_\___|  \_/_/   \_\_| |_____|
  **/

  private static Map<Id, Account> buildAccountMap( List<Case> cases )
  {
    Set<Id> acctIds = new Set<Id>();
    for( Case c : cases )
    {
      acctIds.add( c.AccountId );
    }
    return new Map<Id, Account>([SELECT Id, Name FROM Account WHERE ID IN :acctIds]);
  }

  /**
      __  _   _ _____ _   _ _____    _    ____  _     _____  ____
    / _ \| | | | ____| | | | ____|  / \  | __ )| |   | ____/ ___|
   | | | | | | |  _| | | | |  _|   / _ \ |  _ \| |   |  _| \___ \
   | |_| | |_| | |___| |_| | |___ / ___ \| |_) | |___| |___ ___) |
    \__\_\\___/|_____|\___/|_____/_/   \_\____/|_____|_____|____/

   **/

  public class PartnerPartsOrderFromCases_Queue implements Queueable
  {
    public Set<Id> caseIds;

    public PartnerPartsOrderFromCases_Queue()
    {
      this.caseIds = new Set<Id>();
    }

    public PartnerPartsOrderFromCases_Queue( Set<Id> caseIds )
    {
      this.caseIds = caseIds;
    }

    public void execute( QueueableContext context )
    {
      if( this.caseIds == null || this.caseIds.size() == 0 )
        return;

      /* TODO REFACTOR THIS METHOD */
      CreateERPFromClaimCase_ar.createProjectFromCase( this.caseIds );
    }
  }

}
