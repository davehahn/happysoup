/**
 * Created by dave on 2019-11-14.
 */

public without sharing class Case_TriggerHandler extends TriggerHandler
{

  static Id warrantyRecordTypeId { get {
    if( warrantyRecordTypeId == null )
      warrantyRecordTypeId = LGND_Utilities.recordTypeIdFromName('Case', 'Warranty');
    return warrantyRecordTypeId;
  } set; }

  protected override void bulkBefore()
  {
  }

  protected override void bulkAfter()
  {
  }

  protected override void beforeInsert()
  {
    setContactAndPricebookOnPartnerWarrantyCase( (List<Case>)Trigger.new );
    createRequiredWarrantyPayableErps( (List<Case>)Trigger.new );
  }

  protected override void beforeUpdate()
  {
    validateStatusChange( (List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap );
  }

  protected override void beforeDelete()
  {
    deleteRelatedERPs( (List<Case>)Trigger.oldMap.values() );
  }

  protected override void afterInsert()
  {
    createPartnerPartsOrderForApprovedWarrantyCases( (List<Case>)Trigger.new, null );
    makeCommentOnErpAboutCaseNumberAndLink( (List<Case>)Trigger.new );
    handleSubletLines( (List<Case>)Trigger.new, null );
    enforceAssignmentRules( Trigger.newMap.keySet() );
    //new JiraConnect( Trigger.new, Trigger.oldMap ).createIssues();
  }

  protected override void afterUpdate()
  {
    createPartnerPartsOrderForApprovedWarrantyCases( (List<Case>)Trigger.new,
                                                     (Map<Id, Case>)Trigger.oldMap );
    closeLostERPsIfDenied( (List<Case>)Trigger.new,
                           (Map<Id, Case>)Trigger.oldMap );
    handleSubletLines( (List<Case>)Trigger.new,
                       (Map<Id, Case>)Trigger.oldMap );
    addPromotionalProductsToERP( (List<Case>)Trigger.new,
                                 (Map<Id, Case>)Trigger.oldMap );
    //new JiraConnect( Trigger.new, Trigger.oldMap ).updateIssues();
  }

  protected override void afterDelete()
  {
  }

  protected override void afterUndelete()
  {
  }

  protected override void finalActions()
  {
  }

  private static void setContactAndPricebookOnPartnerWarrantyCase( List<Case> newList )
  {
    try
    {
      User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
      for (Case c : newList)
      {
        if (c.RecordTypeId == warrantyRecordTypeId)
        {
          c.Price_Book__c = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
        }
        if (c.ContactId == null)
        {
          c.ContactId = u.ContactId;
        }
      }
    }
    //In case trigger is invoked by automatedProcess and UserInfo will fail
    catch( Exception e ){}
  }

  private static void createRequiredWarrantyPayableErps( List<Case> listNew )
  {
    List<Case> requiresERP_cases = new List<Case>();
    System.debug( listNew.size() );
    System.debug( warrantyRecordTypeId );
    System.debug( listNew[0].RecordTypeId == warrantyRecordTypeId );
    System.debug( listNew[0].Warranty_ERP__c == null );
    for( Case c : listNew )
    {
      System.debug( 'Is Warranty RecordType ? ' + String.valueOf(c.RecordTypeId == warrantyRecordTypeId ));
      System.debug('Warranty ERP is Blank ? ' + String.valueOf(c.Warranty_ERP__c == null ));
      if( c.RecordTypeId == warrantyRecordTypeId  &&
          c.Warranty_ERP__c == null )
      {
        requiresERP_cases.add( c );
      }
    }
    Project_Service.insertWarrantyPayablesFromCases( requiresERP_cases );
  }

  private static void validateStatusChange( List<Case> listNew, Map<Id, Case> oldMap )
  {
    for(Case c : listNew)
    {
      if( c.Can_Add_Parts__c &&
          !oldMap.get(c.Id).Can_Add_Parts__c &&
          c.Parts_Order_ERP__c != null )
      {
        c.Status.addError('This case has a related parts order. Please remove the parts order first to change status.');
      }
    }
  }

  private static void deleteRelatedERPs( List<Case> cases )
  {
    List<AcctSeed__Project__c> erpsToDelete = new List<AcctSeed__Project__c>();
    for( Case c : cases )
    {
      if( c.Warranty_ERP__c != null )
      {
        erpsToDelete.add( new AcctSeed__Project__c(
          Id = c.Warranty_ERP__c
        ));
      }
    }
    delete erpsToDelete;
  }

  private static void createPartnerPartsOrderForApprovedWarrantyCases( List<Case> listNew,
                                                                       Map<Id, Case> oldMap )
  {

    Set<Id> caseIds = new Set<Id>();
    for( case c : listNew )
    {
      if( c.RecordTypeId == warrantyRecordTypeId &&
          c.Status == 'Approved' &&
          c.Parts_Order_ERP__c == null &&
          ( oldMap == null ||
            oldMap != null && oldMap.get(c.Id).Status != 'Approved' ) )
      {
        caseIds.add( c.Id );
      }
    }
    if( caseIds.size() > 0 )
    {
      Project_Service.PartnerPartsOrderFromCases_Queue queue =
        new Project_Service.PartnerPartsOrderFromCases_Queue( caseIds );
      System.enqueueJob( queue );
    }

  }

  private static void makeCommentOnErpAboutCaseNumberAndLink( List<Case> cases )
  {
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>();
    for( Case c : cases )
    {
      if( c.Warranty_ERP__c != null )
      {
        String comment = 'Warranty Case # ' + c.CaseNumber;
        if (c.Partner_Reference__c != null)
          comment += '<br> Partner Reference # ' + c.Partner_Reference__c;
        erps.add( new AcctSeed__Project__c(
          Id = c.Warranty_ERP__c,
          Customer_Notes__c = comment,
          Warranty_Case__c = c.Id
        ));
      }
      Boolean origProjState = gcProject.disableTrigger;
      gcProject.disableTrigger = true;
      update erps;
      gcProject.disableTrigger = origProjState;
    }
  }

  private static void enforceAssignmentRules( Set<Id> caseIds )
  {
    Database.DMLOptions dmlOpts = new Database.DMLOptions();
    dmlOpts.assignmentRuleHeader.useDefaultRule= true;
    dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
    dmlOpts.EmailHeader.triggerUserEmail = true;
    Case[] cases = new List<Case>();
    for( Id caseId : caseIds )
    {
      Case c = new Case( Id = caseId );
      c.setOptions( dmlOpts );
    }
    TriggerHandler.bypass('Case_TriggerHandler');
    update cases;
    TriggerHandler.clearBypass('Case_TriggerHandler');
  }

  private static void handleSubletLines( List<Case> listNew, Map<Id, Case> oldMap )
  {
    List<Case> createSublet = new List<Case>();
    List<Case> changedSublet = new List<Case>();
    Set<Id> removeSubletLine = new Set<Id>();

    for( Case c : listNew )
    {
      Case oldCase = oldMap == null ? null : oldMap.get( c.Id );

      /** SUBLET INFORMATION IS POPULATED **/
      if( c.recordTypeId == warrantyRecordTypeId &&
          c.Sublet_Company__c != null &&
          c.Sublet_Price__c != null &&
          c.Warranty_ERP__c != null )
      {
        /** NEW SUBLET INFORMATION **/
        if( oldCase == null ||
          (oldCase.Sublet_Company__c == null &&
          ( oldCase.Sublet_Price__c == null || oldCase.Sublet_Price__c == 0 ) ) )
        {
          createSublet.add( c );
        }
        /** SUBLET INFORMATION CHANGED **/
        if( oldCase != null &&
            (( oldCase.Sublet_Company__c != null &&
               c.Sublet_Company__c != null &&
               oldCase.Sublet_Company__c != c.Sublet_Company__c ) ||
            ( oldCase.Sublet_Price__c != null &&
              c.Sublet_Price__c != null &&
              oldCase.Sublet_Price__c != c.Sublet_Price__c ) ) )
        {
          changedSublet.add( c );
        }
      }

      /** SUBLET INFORMATION UNPOPULATED **/
      if( oldCase != null &&
          ( c.Sublet_Price__c == null || c.Sublet_Price__c == 0 ) &&
          c.Sublet_Company__c == null &&
          oldCase.Sublet_Price__c != null &&
          oldCase.Sublet_Price__c != 0 &&
          oldCase.Sublet_Company__c != null &&
          c.Warranty_ERP__c != null )
      {
        removeSubletLine.add( c.Warranty_ERP__c );
      }
    }
    handleCreateSublet( createSublet );
    handleUpdateSublet( changedSublet );
    handleDeleteSublet( removeSubletLine );
  }

  private static void handleCreateSublet( List<Case> cases )
  {
    String tn = '%' + ProjectTask_Service.warrantyPayableTaskName + '%';
    Map<Id, Case> erpId_Case_Map = new Map<Id, Case>();
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    for( Case c : cases  )
    {
      erpId_Case_Map.put( c.Warranty_ERP__c, c );
    }
    for( AcctSeed__Project__c p : [ SELECT Id,
                                    ( SELECT Id
                                      FROM AcctSeed__Project_Tasks__r
                                      WHERE Name LIKE :tn
                                      LIMIT 1 )
                                    FROM AcctSeed__Project__c
                                    WHERE Id IN :erpId_Case_Map.keySet() ] )
    {
      if( p.AcctSeed__Project_Tasks__r.size() > 0 )
      {
        Case c = erpId_Case_Map.get(p.Id);
        mats.add( CaseLexController.createSubletMaterialLine( p.Id,
                                                              p.AcctSeed__Project_Tasks__r[0].Id,
                                                              c.Sublet_Price__c,
                                                              c.Sublet_Company__c) );
      }
    }
    insert mats;
  }

  private static void handleUpdateSublet( List<Case> cases )
  {
    Map<Id, Case> caseMap = new Map<Id, Case>();
    for( Case c : cases )
    {
      caseMap.put( c.Warranty_ERP__c, c );
    }
    AcctSeedERP__Material__c[] mats = [ SELECT Id, AcctSeedERP__Project__c
                                        FROM AcctSeedERP__Material__c
                                        WHERE AcctSeedERP__Project__c = :caseMap.keySet()
                                        AND AcctSeedERP__Product__c = :Utility_Products__c.getOrgDefaults().Sublet__c];
    for( AcctSeedERP__Material__c m : mats )
    {
      Case c = caseMap.get( m.AcctSeedERP__Project__c );
      m.AcctSeedERP__Comment__c = c.Sublet_Company__c;
      m.GMBLASERP__Unit_Price__c = c.Sublet_Price__c;
    }
    update mats;
  }

  private static void handleDeleteSublet( Set<Id> erpids )
  {
    AcctSeedERP__Material__c[] mats = [ SELECT Id
                                        FROM AcctSeedERP__Material__c
                                        WHERE AcctSeedERP__Project__c = :erpIds
                                        AND AcctSeedERP__Product__c = :Utility_Products__c.getOrgDefaults().Sublet__c];
    delete mats;
  }

  private static void closeLostERPsIfDenied( List<Case> listNew,
                                             Map<Id, Case> oldMap )
  {
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>();
    for( Case c : listNew )
    {
      Case oldCase = oldMap.get(c.Id);
      if( c.Status == 'Denied' &&
          oldCase.Status != 'Denied' )
      {
        if( c.Warranty_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Warranty_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
        if( c.Recoverable_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Recoverable_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
        if( c.Parts_Order_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Parts_Order_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
      }
      update erps;
    }
  }

  private static void addPromotionalProductsToERP( List<Case> listNew, Map<Id, Case> oldMap )
  {
    Map<String, String> applicableData = new Map<String, String>();
    Id promoRtId = LGND_Constants.caseRtId_Promotion;
    for( Case c : listNew )
    {
      if( c.RecordTypeId == promoRtId &&
          c.Promotion_ERP__c != null &&
          c.PromotionId__c != null &&
          c.Status == 'Complete' &&
          oldMap.get(c.Id).Status != 'Complete' )
      {
        applicableData.put(
          c.Promotion_ERP__c, c.PromotionId__c
        );
      }
    }
    if( applicableData.size() > 0 )
    {
      AddPromotionalItems_Queue queue = new AddPromotionalItems_Queue( applicableData );
      System.enqueueJob( queue );
    }
  }

  public class AddPromotionalItems_Queue implements Queueable
  {
    public Map<String, String> erpToPromoMap;

    public AddPromotionalItems_Queue()
    {
      this.erpToPromoMap = new Map<String, String>();
    }

    public AddPromotionalItems_Queue( Map<String, String> erpToPromoMap )
    {
      this.erpToPromoMap = erpToPromoMap;
    }

    public void execute( QueueableContext context )
    {
      if( this.erpToPromoMap == null || this.erpToPromoMap.size() == 0 )
        return;

      Map<Id, Promotion_Incentive_Product__c> promotionToPromoProductsMap = new Map<Id, Promotion_Incentive_Product__c>();
      Map<Id, Promotion__c> promotions = new Map<Id, Promotion__c>([
        SELECT
          Id,
          Name,
        ( SELECT
            Id,
            Product__c,
            Quantity__c
          FROM Promotion_Incentive_Products__r
        )
        FROM Promotion__c
        WHERE Id IN :this.erpToPromoMap.values()
      ]);
      Map<Id, AcctSeed__Project_Task__c> erpToTaskMap = new Map<Id, AcctSeed__Project_Task__c>();
      for( String erpId : this.erpToPromoMap.keySet() )
      {
        String promoId = this.erpToPromoMap.get( erpId );
        if( promotions.get( promoId ).Promotion_Incentive_Products__r.size() > 0 )
        {
          erpToTaskMap.put( erpId, new AcctSeed__Project_Task__c(
            AcctSeed__Project__c = erpId,
            Name = 'Promotion Items',
            DisplayOnCustomerInvoice__c = true
          ));
        }
      }
      if( erpToTaskMap.values().size() > 0 )
      {
        insert erpToTaskMap.values();
        List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
        for (String erpId : this.erpToPromoMap.keySet())
        {
          String promoId = this.erpToPromoMap.get(erpId);
          if (erpToTaskMap.containsKey(erpId))
          {
            for (Promotion_Incentive_Product__c iProd : promotions.get(promoId).Promotion_Incentive_Products__r)
            {
              mats.add(new AcctSeedERP__Material__c(
                AcctSeedERP__Project__c = erpId,
                AcctSeedERP__Project_Task__c = erpToTaskMap.get(erpId).Id,
                AcctSeedERP__Product__c = iProd.Product__c,
                AcctSeedERP__Quantity_Per_Unit__c = iProd.Quantity__c,
                GMBLASERP__Unit_Price__c = 0,
                GMBLASERP__Price_Override__c = true,
                AcctSeedERP__Comment__c = promotions.get(promoId).Name
              ));
            }
          }
        }
        insert mats;
      }
    }
  }
}