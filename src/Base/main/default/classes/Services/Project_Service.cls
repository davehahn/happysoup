/**
 * Created by dave on 2019-11-14.
 */

public inherited sharing class Project_Service {
  public static Application_RecordType.ERPOrderRTs recordTypes {
    get {
      if (recordTypes == null) {
        recordTypes = new Application_RecordType().getERPOrderRecordTypes();
      }
      return recordTypes;
    }
    set {
    }
  }

  public class Project {
    public AcctSeed__Project__c record;
    public Opportunity opportunity;

    private Application_RecordType.ERPOrderRTs recordTypes;

    public Project() {
      this.recordTypes = new Application_RecordType.ERPOrderRTs();
    }

    public AcctSeed__Project__c getRecord() {
      return this.record;
    }

    public Project buildFromOpportunity(Opportunity opp) {
      this.opportunity = opp;
      buildRecordFromOpp();
      Application_RecordType.OpportunityRTs rts = new Application_RecordType.OpportunityRTs();
      if (this.opportunity.RecordTypeId == rts.getRetailId()) {
        configureForRetailBoatSale();
      }
      if (this.opportunity.RecordTypeId == rts.getOnlineId()) {
        if (this.opportunity.IsPickupDealershipPartner__c) {
          configureForPartnerRetailBoatSale();
        } else {
          configureForRetailBoatSale();
        }
      }
      return this;
    }

    public Project newFromOpportunity(Opportunity opp) {
      this.buildFromOpportunity(opp);
      insert this.record;
      return this;
    }

    public Project newFromOpportunityId(Id oppId) {
      try {
        return newFromOpportunity(Opportunity_Selector.selectAllByIdWithLineItems(new Set<Id>{ oppId })[0]);
      } catch (Exception e) {
        throw new Application_Selector.SelectorException('Opportunity not found, invalid Id supplied');
      }
    }

    private void configureForRetailBoatSale() {
      this.record.RecordTypeId = this.recordTypes.getRetailBoatSaleId();
      this.record.Stage__c = 'Tagging Pending';
    }

    private void configureForPartnerRetailBoatSale() {
      this.record.RecordTypeId = this.recordTypes.getPartnerRetailBoatSaleId();
      this.record.Stage__c = 'Tagging Pending';
    }

    private void buildRecordFromOpp() {
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
        Insurance_Term__c = this.opportunity.Insurance_Term__c,
        Financing_Account__c = this.opportunity.Financing_Account__c,
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
      if (this.opportunity.Tax_Override__c == true) {
        this.record.Tax_Rate_Federal__c = this.opportunity.Tax_Rate_Federal__c;
        this.record.Tax_Rate_Provincial__c = this.opportunity.Tax_Rate_Provincial__c;
        this.record.Tax_Rate_Retail__c = this.opportunity.Tax_Rate_Retail__c;
      }
      if (this.record.GMBLASERP__Warehouse__c == null) {
        this.record.GMBLASERP__Warehouse__c = Warehouse_Selector.selectDefaultWarehouseForUser().Id;
      }
      if (this.record.Payment_Method__c == 'Finance') {
        this.record.Payment_Status__c = 'Approved for Financing';
      }
    }
  }

  public static AcctSeed__Project__c newFromOpportunityId(Id oppId) {
    Opportunity opp = Opportunity_Selector.selectAllByIdWithLineItems(new Set<Id>{ oppId })[0];

    Project project = new Project().newFromOpportunity(opp);

    Map<String, AcctSeed__Project_Task__c> projectTasks = ProjectTask_Service.insertDefaultTasks(project.getRecord());
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    Material_Service.Material_Builder matBuilder = new Material_Service.Material_Builder(
      project.getRecord().Id,
      projectTasks.get('Sale').Id,
      projectTasks.get('Business Office').Id
    );

    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
      materials.add(matBuilder.buildFromOppLineItem(oli));
    }
    /// Add material lines for Trade In
    materials.addAll(
      Material_Service.buildTradeInMaterialsFromOpportunity(opp, project.getRecord().Id, projectTasks.get('Sale').Id)
    );

    insert materials;

    opp.StageName = 'Sent to ERP';
    // Boolean oldOppyTriggerVal = OpportunityTriggerHandler.disableTrigger;
    //OpportunityTriggerHandler.disableTrigger = true;
    TriggerBase.bypass('Opportunity');
    update opp;
    TriggerBase.clearBypass('Opportunity');
    // OpportunityTriggerHandler.disableTrigger = oldOppyTriggerVal;
    /// Lock the task now
    AcctSeed__Project_Task__c salesTask = [
      SELECT Id, Name
      FROM AcctSeed__Project_Task__c
      WHERE Id = :projectTasks.get('Sale').Id
    ];
    salesTask.Locked__c = true;
    Boolean oldTaskVal = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    update salesTask;
    gcProjectTask.disableTrigger = oldTaskVal;
    return project.getRecord();
  }

  public static List<Case> insertWarrantyPayablesFromCases(List<Case> cases) {
    Map<Id, Account> accountMap = buildAccountMap(cases);
    Map<String, Case> caseMap = new Map<String, Case>();
    Map<String, AcctSeed__Project__c> projectMap = new Map<String, AcctSeed__Project__c>();

    for (Case c : cases) {
      String id = LGND_Utilities.generateRandomString(6);
      caseMap.put(id, c);
      String accountName = accountMap.containsKey(c.AccountId) ? accountMap.get(c.AccountId).Name : '';
      projectMap.put(id, buildWarrantyPayableFromCase(c, accountName));
    }
    insert projectMap.values();

    ProjectTask_Service.insertWarrantyPayableTasksForProjects(projectMap.values());

    for (String key : caseMap.keySet()) {
      caseMap.get(key).Warranty_ERP__c = projectMap.get(key).Id;
    }
    return caseMap.values();
  }

  public static AcctSeed__Project__c buildWarrantyPayableFromCase(Case c, String accountName) {
    return new AcctSeed__Project__c(
      Name = accountName.trim(),
      RecordTypeId = recordTypes.getWarrantyId(),
      AcctSeed__Account__c = c.AccountId,
      Serial_Number__c = c.Serial_Number__c,
      GMBLASERP__Pricebook__c = c.Price_Book__c
    );
  }

  public static void handlePartnerToRetailBoatSaleLinkChanges(
    List<AcctSeed__Project__c> listNew,
    Map<Id, AcctSeed__Project__c> oldMap
  ) {
    Map<Id, AcctSeed__Project__c> retailErps = new Map<Id, AcctSeed__Project__c>();
    Map<Id, AcctSeed__Project__c> linkedRetailHasChanged = new Map<Id, AcctSeed__Project__c>();
    for (AcctSeed__Project__c erp : listNew) {
      if (erp.RecordTypeId == recordTypes.getPartnerBoatSaleId()) {
        if (oldMap != null && oldMap.size() > 0) {
          if (erp.Retail_ERP__c != oldMap.get(erp.Id).Retail_ERP__c) {
            if (erp.Retail_ERP__c == null) {
              //Clear old Retail ERP Arrival Data
              retailErps.put(
                oldMap.get(erp.Id).Retail_ERP__c,
                new AcctSeed__Project__c(Id = oldMap.get(erp.Id).Retail_ERP__c, Arrival_Date__c = null)
              );
            } else {
              //Linked ERP has changes so update the arrival date on new linked retail
              linkedRetailHasChanged.put(erp.Id, erp);
              if (oldMap.get(erp.Id).Retail_ERP__c != null) {
                retailErps.put(
                  oldMap.get(erp.Id).Retail_ERP__c,
                  new AcctSeed__Project__c(Id = oldMap.get(erp.Id).Retail_ERP__c, Arrival_Date__c = null)
                );
              }
            }
          }
        } else {
          //This is an insert operation
          if (erp.Retail_ERP__c != null) {
            linkedRetailHasChanged.put(erp.Id, erp);
          }
        }
      }
    }
    // if the linked Retail erp has changed, then retrieve the deliverDate
    // from the po line linked to partner order and update the arrival date
    // on the Retail ERP
    if (linkedRetailHasChanged.size() > 0) {
      for (
        AcctSeedERP__Purchase_Order_Line__c pol : PurchaseOrderLine_Selector.allByProjectId(
          linkedRetailHasChanged.keySet()
        )
      ) {
        if (pol.deliverDate__c != null) {
          retailERPs.put(
            linkedRetailHasChanged.get(pol.AcctSeedERP__Project__c).Retail_ERP__c,
            new AcctSeed__Project__c(
              Id = linkedRetailHasChanged.get(pol.AcctSeedERP__Project__c).Retail_ERP__c,
              Arrival_Date__c = pol.deliverDate__c
            )
          );
        }
      }
    }
    System.debug(retailERPs.values());
    update retailERPs.values();
  }

  public static AcctSeed__Project__c buildBackOrder(AcctSeed__Project__c originalERP) {
    /// SFISSUES-1310
    Id idPartsService = gcConstants.idGlv2PartsAndService;
    return new AcctSeed__Project__c(
      RecordTypeId = recordTypes.getServiceWorkOrderId(),
      Salesperson__c = originalERP.Salesperson__c,
      Name = originalERP.AcctSeed__Account__r.Name + '-Back Order',
      Stage__c = 'Pending Diagnostic',
      Job_Status__c = 'Boat Required',
      Original_ERP__c = originalERP.Id,
      AcctSeed__Account__c = originalERP.AcctSeed__Account__c,
      GMBLASERP__Warehouse__c = originalERP.GMBLASERP__Warehouse__c,
      GL_Account_Variable_1__c = originalERP.GL_Account_Variable_1__c,
      //GL_Account_Variable_2__c = originalERP.GL_Account_Variable_2__c,
      GL_Account_Variable_2__c = idPartsService,
      GL_Account_Variable_3__c = originalERP.GL_Account_Variable_3__c,
      Serial_Number__c = originalERP.Serial_Number__c,
      Serial_Number__r = originalERP.Serial_Number__r,
      Survey_Flag__c = false
    );
  }

  public static void createFlexibleAccessoryCreditProjects(Set<Id> retailIds) {
    List<AcctSeedERP__Material__c> origMats = Material_Selector.allFlexibleAccessoryCreditLinesByProjectIds(retailIds);
    Map<Id, AcctSeed__Project__c> newProjectByOriginalProjectId = new Map<Id, AcctSeed__Project__c>();
    Map<Id, AcctSeed__Project_Task__c> taskByProjectId = new Map<Id, AcctSeed__Project_Task__c>();
    List<AcctSeedERP__Material__c> newMats = new List<AcctSeedERP__Material__c>();

    //Create the Projects
    for (AcctSeedERP__Material__c mat : origMats) {
      Id boatSpecialist = mat.AcctSeedERP__Project__r.Boat_Specialist__c == null
        ? mat.AcctSeedERP__Project__r.Salesperson__c
        : mat.AcctSeedERP__Project__r.Boat_Specialist__c;
      newProjectByOriginalProjectId.put(
        mat.AcctSeedERP__Project__c,
        new AcctSeed__Project__c(
          RecordTypeId = recordTypes.getServiceWorkOrderId(),
          Name = mat.AcctSeedERP__Project__r.AcctSeed__Account__r.Name + '-FAC',
          Salesperson__c = boatSpecialist,
          OwnerId = boatSpecialist,
          AcctSeed__Account__c = mat.AcctSeedERP__Project__r.AcctSeed__Account__c,
          Serial_Number__c = mat.AcctSeedERP__Project__r.Serial_Number__c,
          Stage__c = 'Pending Diagnostic',
          GMBLASERP__Warehouse__c = mat.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
          GL_Account_Variable_1__c = mat.AcctSeedERP__Project__r.GL_Account_Variable_1__c,
          GL_Account_Variable_2__c = mat.AcctSeedERP__Project__r.GL_Account_Variable_2__c,
          GL_Account_Variable_3__c = mat.AcctSeedERP__Project__r.GL_Account_Variable_3__c,
          Survey_Flag__c = false
        )
      );
    }
    insert newProjectByOriginalProjectId.values();

    //Create the tasks
    for (AcctSeedERP__Material__c mat : origMats) {
      taskByProjectId.put(
        newProjectByOriginalProjectId.get(mat.AcctSeedERP__Project__c).Id,
        ProjectTask_Service.buildFlexibleAccessoryCreditTask(
          newProjectByOriginalProjectId.get(mat.AcctSeedERP__Project__c),
          mat.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c
        )
      );
    }
    insert taskByProjectId.values();

    //Create Materials
    for (AcctSeedERP__Material__c mat : origMats) {
      Id newProjectId = newProjectByOriginalProjectId.get(mat.AcctSeedERP__Project__c).Id;
      newMats.add(
        new AcctSeedERP__Material__c(
          AcctSeedERP__Project__c = newProjectId,
          AcctSeedERP__Project_Task__c = taskByProjectId.get(newProjectId).Id,
          AcctSeedERP__Product__c = mat.AcctSeedERP__Product__c,
          AcctSeedERP__Quantity_Per_Unit__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
          GMBLASERP__Price_Override__c = mat.GMBLASERP__Price_Override__c,
          GMBLASERP__Unit_Price__c = mat.GMBLASERP__Unit_Price__c
        )
      );
    }
    insert newMats;

    //Lock the tasks
    for (AcctSeed__Project_Task__c task : taskByProjectId.values()) {
      task.Locked__c = true;
    }
    update taskByProjectId.values();
  }

  /**
      ____  ____  _____     ___  _____ _____
     |  _ \|  _ \|_ _\ \   / / \|_   _| ____|
     | |_) | |_) || | \ \ / / _ \ | | |  _|
     |  __/|  _ < | |  \ V / ___ \| | | |___
     |_|   |_| \_\___|  \_/_/   \_\_| |_____|

  **/

  private static Map<Id, Account> buildAccountMap(List<Case> cases) {
    Set<Id> acctIds = new Set<Id>();
    for (Case c : cases) {
      acctIds.add(c.AccountId);
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

  public class PartnerPartsOrderFromCases_Queue implements Queueable {
    public Set<Id> caseIds;

    public PartnerPartsOrderFromCases_Queue() {
      this.caseIds = new Set<Id>();
    }

    public PartnerPartsOrderFromCases_Queue(Set<Id> caseIds) {
      this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
      if (this.caseIds == null || this.caseIds.size() == 0)
        return;

      /* TODO REFACTOR THIS METHOD */
      CreateERPFromClaimCase_ar.createProjectFromCase(this.caseIds);
    }
  }
}
