global with sharing class OpportunityExt_FI {

  public class WarrantyAndServiceItem {
    public String OpportunityId { get; set; }
    public String PricebookEntryId { get; set; }
    public String ProductName { get; set; }
    public Decimal UnitPrice { get; set; }
    public String OpportunityLineItemId { get; set; }
    public Boolean isSelected { get; set; }

    public WarrantyAndServiceItem(){
      this.isSelected = false;
      this.OpportunityLineItemId = '';
    }

  }

  private final ApexPages.StandardController std;
  public Id oppId { get; set; }
  public String oppPricebookId { get; set; }
  public OpportunityLineItem[] fiItems{ get; set; }
  public WarrantyAndServiceItem[] warAndServItems { get; set; }
  public Boolean hasInvoice { get; set; }
  public String planId {get; set;}
  public Map<String, Map<String, Set<String>>> planOptionsMap { get; set; }
  public Map<Id, PricebookEntry> planItems { get; set; }
  public OpportunityLineItem ppsaFee { get; set; }
  transient Opportunity opp;
  public Id ppsaFeePricebookEntryId { get; set; }
  public String pbName { get; set; }

  global OpportunityExt_FI(ApexPages.StandardController stdCrl) {
    this.std = stdCrl;
    this.oppId = std.getId();
    if(oppId != null)
    {
      opp = [SELECT Id, Invoice_Document_Id__c, Pricebook2Id, Pricebook2.Name FROM Opportunity WHERE Id = :oppId];
      this.oppPricebookId = opp.Pricebook2Id;
      this.pbName = opp.Pricebook2.Name;
      this.ppsaFeePricebookEntryId = findPpsaPricebookEntryId();
      this.ppsaFee = findPpsaFee();
      this.hasInvoice = opp.Invoice_Document_Id__c != null;
      this.fiItems = [SELECT Id,
                             Description,
                             Quantity,
                             InsuranceCoverage__c,
                             PricebookEntryId,
                             Insurance_Rate__c,
                             PricebookEntry.Product2Id,
                             PricebookEntry.Product2.Name,
                             PricebookEntry.Product2.InsurancePlan__c,
                             PricebookEntry.Product2.InsurancePlan__r.Name,
                             UnitPrice
                       FROM OpportunityLineItem
                       WHERE OpportunityId = :this.oppId
                       AND isInsurance__c = true];
      this.warAndServItems = fetchAvailableWarranyAndServiceItems(oppId);
      if( !fiItems.isEmpty() )
      {
        planId = fiItems[0].PricebookEntry.Product2.InsurancePlan__c;
        planItems = fetchPlanItems(planId, oppPricebookId);
      }
    }
  }

  public Map<Id,InsurancePlan__c> getPlans()
  {
    Map<Id, InsurancePlan__c> plans = new Map<Id, InsurancePlan__c>([SELECT Id, Name FROM InsurancePlan__c]);
    return plans;
  }

  public List<String> getCoverageOptions()
  {
    return LGND_Utilities.getPicklistValues('OpportunityLineItem', 'InsuranceCoverage__c');
  }

  public String getJSONcoverageOptions()
  {
    return JSON.serialize( getCoverageOptions() );
  }

  public Map<String, Map<String,String>> getPlanOptions()
  {
    if( planId == null || planId == '')
    {
      return null;
    }
    return groupedPlanOptions(planId, oppPricebookId);
  }

  public Boolean getRenderTable()
  {
    return planId == null || planId == '' ? false : true;
  }

  public void planChanged()
  {
    planId = Apexpages.currentPage().getParameters().get('planId');
    List<OpportunityLineItem> items = [SELECT Id
                                       FROM OpportunityLineItem
                                       WHERE OpportunityId = :oppId
                                       AND isInsurance__c = true];
    delete items;
    fiItems = new List<OpportunityLineItem>();
  }

  public PageReference updateInvoiceAndReturn()
  {
    try
    {
      Opportunity opp = [Select Id, Name FROM Opportunity WHERE Id = :oppId];
      //String fileName = opp.Name + ' - ' + Datetime.Now().format() + '.pdf';
      Document doc = OpportunityDocumentBuilder.buildInvoicePDF(opp, 'english');
      opp.Invoice_Document_Id__c = doc.Id;
      update opp;
      return new PageReference('/' + opp.Id);
    }
    catch(Exception e)
    {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() );
      ApexPages.addmessage(myMsg);
      return null;
    }
  }

  /* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                  REMOTE ACTIONS
   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  @RemoteAction
  global static Map<String, Map<String,String>> planSelectOptions(String planId, String pbId)
  {
    return groupedPlanOptions(planId, pbId);
  }

  @RemoteAction
  global static OpportunityLineItem selectWarrantyOrServiceItem(String pricebookEntryId, String oppId)
  {
    PricebookEntry pbe = [SELECT Id, UnitPrice, Product2.Name
                          FROM PricebookEntry
                          WHERE Id = :pricebookEntryId];
    OpportunityLineItem oli = new OpportunityLineItem( PricebookEntryId = pbe.Id,
                                                        UnitPrice = pbe.UnitPrice,
                                                        Quantity = 1,
                                                        Description = pbe.Product2.Name,
                                                        OpportunityId = oppId,
                                                        BoatBuilderItem__c = true
                                                        );
    insert oli;
    //try {
    //   CommissionRecord__c cRecord  = [SELECT Id
    //                                    FROM CommissionRecord__c
    //                                    WHERE OpportunityId__c = : oppId
    //                                    AND Type__c = 'Business Office' ];
    //  CommissionLineItem__c cli = CommissionLineItem.newFromOpportunitylineItemId( oli.Id );
    //  cli.CommissionRecord__c = cRecord.Id;
    //  insert cli;
    //}
    //catch(Exception e){}

    //createCommissionLineItem(oli);
    return oli;
  }

  @RemoteAction
  global static OpportunityLineItem removeWarrantyOrServiceItem(String oppLineItemId)
  {
    OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE Id = :oppLineItemId];
    delete oli;
    return oli;
  }

  @RemoteAction
  global static OpportunityLineItem saveItem(String jsonData)
  {
      system.debug(jsonData);
     OpportunityLineItem item = (OpportunityLineItem)JSON.deserialize(jsonData, OpportunityLineItem.class);
     upsert item;
     return [SELECT Id,
                    Description,
                    Quantity,
                    InsuranceCoverage__c,
                    PricebookEntryId,
                    PricebookEntry.Product2Id,
                    PricebookEntry.Product2.Name,
                    PricebookEntry.Product2.InsurancePlan__c,
                    PricebookEntry.Product2.InsurancePlan__r.Name,
                    UnitPrice
             FROM OpportunityLineItem
             WHERE Id = :item.Id];
  }

  @RemoteAction
  global static void deleteItem(String itemId)
  {
    OpportunityLineItem item = [SELECT Id FROM OpportunityLineItem WHERE Id = :itemId];
    delete item;
  }

  @RemoteAction
  global static OpportunityLineItem savePPSA( String jsonData )
  {
    OpportunityLineItem oli = (OpportunityLineItem)JSON.Deserialize( jsonData, OpportunityLineItem.class);
    if( oli.UnitPrice == null || oli.UnitPrice == 0 )
    {
      delete oli;
      return null;
    }
    oli.isDiscount__c = false;
    oli.quantity = 1;
    //oli.BoatBuilderItem__c = true;
    upsert oli;
    return oli;
  }

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                  PRIVATES
   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  private Id findPpsaPricebookEntryId()
  {
    try
    {
      return [SELECT Id
              FROM PricebookEntry
              WHERE Pricebook2Id = :opp.Pricebook2Id
              AND Product2.Family = 'Bank Registration PPSA Fee'
              AND Product2.RecordType.Name = 'Fees' ].Id;
    }
    catch(Exception e)
    {
      return null;
    }
  }

  private OpportunityLineItem findPpsaFee()
  {
    if( this.ppsaFeePricebookEntryId != null )
    {
      try
      {
        return [SELECT Id, UnitPrice, OpportunityId, PricebookEntryId
                FROM OpportunityLineItem
                WHERE OpportunityId = :this.oppId
                AND PricebookEntryId = :this.ppsaFeePricebookEntryId];
      }
      catch( Exception e)
      {
        return new OpportunityLineItem(
          OpportunityId = this.oppId,
          PricebookEntryId = this.ppsaFeePricebookEntryId
        );
      }
    }
    return null;
  }

  private static Map<String, Map<String, String>> groupedPlanOptions(String planId, String pbId)
  {

    System.debug('Enter in group plan optionnn');
    Map<Id, PricebookEntry> planItems = fetchPlanItems(planId, pbId);
    Map<String, Map<String, String>> planOptionsMap = new Map<String, Map<String, String>>();
    for( PricebookEntry pItem :planItems.values() )
    {
      if( !planOptionsMap.containsKey(pItem.Product2.Family) )
      {
        planOptionsMap.put(pItem.Product2.Family, new Map<string,String>() );
      }
      planOptionsMap.get(pItem.Product2.Family).put(pItem.Id, pItem.Product2.Name);
    }

    return planOptionsMap;
  }


  private static Map<Id, PricebookEntry> fetchPlanItems( String planId, String pbId )
  {
    return new Map<Id, PricebookEntry>([SELECT Id,
                                               Product2.Name,
                                               Product2Id,
                                               Product2.Family
                                        FROM PricebookEntry
                                        WHERE Pricebook2Id = :pbId
                                        AND Product2.InsurancePlan__c = :planId]);
  }

  private WarrantyAndServiceItem[] fetchAvailableWarranyAndServiceItems(Id oppId)
  {
    WarrantyAndServiceItem[] availItems = new List<WarrantyAndServiceItem>();
    OpportunityLineItem[] oppLineItems = [ SELECT Id,
                                                  PricebookEntryId,
                                                  PricebookEntry.Pricebook2Id,
                                                  PricebookEntry.Product2Id,
                                                  OpportunityId
                                           FROM OpportunityLineItem
                                           WHERE OpportunityId = :oppId ];

    if( !oppLineItems.isEmpty() )
    {
      //map of <Product2Id, OpportunityLineItemId> for later use
      Map<Id, Id> p2Ids = new Map<Id, Id>();
      Id pbId = oppLineItems[0].PricebookEntry.Pricebook2Id;
      for( OpportunityLineItem oli : oppLineItems )
      {
        p2Ids.put(oli.PricebookEntry.Product2Id, oli.Id);
      }

      Product_Option__c[] options = [SELECT Id, From_Product__c
                                     FROM Product_Option__c
                                     WHERE To_Product__c IN :p2Ids.keySet()
                                     AND  ( From_Product__r.Family = 'Extended Warranty'
                                           OR From_Product__r.RecordType.Name = 'Protection and Services')
                                     ];

      if( !options.isEmpty() )
      {
        Set<Id> availIds = new Set<Id>();
        for( Product_Option__c po : options )
        {
          availIds.add(po.From_Product__c);
        }

        PricebookEntry[] pbItems = [SELECT Id, Product2Id, Product2.Name, UnitPrice
                      FROM PricebookEntry
                      WHERE Pricebook2Id = :pbId
                      AND Product2Id IN :availIds];

        for(PricebookEntry pbe : pbItems)
        {
          WarrantyAndServiceItem wsItem = new WarrantyAndServiceItem();
          wsItem.OpportunityId = oppId;
          wsItem.PricebookEntryId = pbe.id;
          wsItem.ProductName = pbe.Product2.Name;
          wsItem.UnitPrice = pbe.UnitPrice;
          if( p2Ids.containsKey(pbe.Product2Id) )
          {
            wsItem.isSelected = true;
            wsItem.OpportunityLineItemId = p2Ids.get(pbe.Product2Id);
          }
          availItems.add( wsItem );
        }
      }

    }
    return availItems;

  }

  @RemoteAction
  public static Decimal populateAmount(String priceBookId, String coverage , String oppId, string LineItemId) {

    PricebookEntry objPriceBookEntry = [Select Product2Id from PricebookEntry WHERE id =: priceBookId];

    Decimal amount = 0.0;

    Opportunity objOpp = [SELECT Id,
                                 GL_Account_Variable_3__c,
                                 Calculate_Insurance_Amount__c,
                                 Deposit__c,
                                 Pre_Insurance_Total__c,
                                 TotalTaxes__c,
                                 Finance_Term__c
                            FROM Opportunity
                           WHERE Id =: oppId ];

    for(Insurance_Rate__c objCompanion : [SELECT Id,
                                                 Joint__c,
                                                 Single__c
                                            FROM Insurance_Rate__c
                                           WHERE Product__c =: objPriceBookEntry.Product2Id
                                             AND Lower_Term__c <=: objOpp.Insurance_Term__c
                                             AND Upper_Term__c >=: objOpp.Insurance_Term__c
                                             AND Lower_Finance_Term__c <=: objOpp.Finance_Term__c
                                             AND Upper_Finance_Term__c >=: objOpp.Finance_Term__c
                                             AND Tax_Zone__c =: objOpp.GL_Account_Variable_3__c ])
    {
      if(coverage == 'Joint') {
        amount = (objCompanion.Joint__c * objOpp.Calculate_Insurance_Amount__c ) / 100;
        if(LineItemId != 'new'){
          OpportunityLineItem opl = new OpportunityLineItem();
          opl.Id = LineItemId;
          opl.Insurance_Rate__c  = objCompanion.Joint__c ;
          update opl;
        }
      } else if(coverage == 'Single') {
        amount = (objCompanion.Single__c * objOpp.Calculate_Insurance_Amount__c) / 100;
        if(LineItemId != 'new') {
          OpportunityLineItem opl = new OpportunityLineItem();
          opl.Id = LineItemId;
          opl.Insurance_Rate__c  = objCompanion.Single__c;
          update opl;
        }
      }
    }
    return amount;
  }
}