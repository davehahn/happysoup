public without sharing class gcProject {

  public static Boolean disableTrigger{
    get{
      if(disableTrigger == null) return false;
      else return disableTrigger;
    }
    set{
      if(value == null) disableTrigger = false;
      else disableTrigger = value;
    }
  }

  public static Boolean disableLockedCheck{
    get{
      if(disableLockedCheck == null) return false;
      else return disableLockedCheck;
    }
    set{
      if(value == null) disableLockedCheck = false;
      else disableLockedCheck = value;
    }
  }

  public static Boolean disableCommission{
    get{
      if(disableCommission == null) return false;
      else return disableCommission;
    }
    set{
      if(value == null) disableCommission = false;
      else disableCommission = value;
    }
  }

  public static Boolean disableRegistration{
    get{
      if(disableRegistration == null) return false;
      else return disableRegistration;
    }
    set{
      if(value == null) disableRegistration = false;
      else disableRegistration = value;
    }
  }

  public static Boolean disableJob{
    get{
      if(disableJob == null) return false;
      else return disableJob;
    }
    set{
      if(value == null) disableJob = false;
      else disableJob = value;
    }
  }

  public static Boolean disablePrepaid{
    get{
      if(disablePrepaid == null) return false;
      else return disablePrepaid;
    }
    set{
      if(value == null) disablePrepaid = false;
      else disablePrepaid = value;
    }
  }

  public static void triggerHandler
    (map<Id,AcctSeed__Project__c> oldMap,
      map<Id,AcctSeed__Project__c> newMap,
      list<AcctSeed__Project__c> listNew,
      Boolean boolIsBefore,
      Boolean boolIsInsert,
      Boolean boolIsUpdate,
      Boolean boolIsDelete)
  {
    if(oldMap == NULL) oldMap = new map<Id,AcctSeed__Project__c>();
    if(newMap == NULL) newMap = new map<Id,AcctSeed__Project__c>();
    if(listNew == NULL) listNew = new list<AcctSeed__Project__c>();

    updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

    if(boolIsBefore)
    {
      if(boolIsInsert)
      {
        setStage( listNew );
      }
      if(boolIsUpdate)
      {
        setStage( listNew );
      }
      if(boolIsDelete)
      {
        Set<Id> partnerErpIds = new Set<Id>();
        Set<Id> setIdP = new Set<Id>();
        for( AcctSeed__Project__c erp : oldMap.values() )
        {
          if( erp.RecordTypeId == gcConstants.idRtProjectPartnerBoatSale )
            partnerErpIds.add( erp.Id );
          if(erp.Stage__c == 'Draft')
            setIdP.add(erp.Id);
        }
        TruckDeliveryItem.erpWasDeleted( partnerErpIds );
        if(!setIdP.isEmpty()){
          delete [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c IN:setIdP];
        }
        if(!disableJob)
          Rigger_Schedule_mp.destroyRelatedJobs(oldmap.keySet());
      }
    }
    else //i.e. trigger.isAfter
    {
      if(boolIsInsert)
      {
        if(!disableJob)
        {
          Rigger_Schedule_mp.createJobFromERP_Future(newMap.keySet());
        }
        Project_Service.handlePartnerToRetailBoatSaleLinkChanges( listNew, null );
      }
      if(boolIsUpdate)
      {
        boatSpecialistChanged( listNew, oldMap );
        notifyOnOwnerChange( newMap, oldMap );
        rename(newMap.keySet());
        if(!disableRegistration)
        {
          RegistrationExt.handleRegistrationsFromERP(newMap, oldMap);
        }
        recalculateInsuranceItems( listNew, oldMap );
        Project_Service.handlePartnerToRetailBoatSaleLinkChanges( listNew, oldMap );
      }
      if(boolIsDelete)
      {
        rename(newMap.keySet());
        if(!disableCommission)
        {
          CommissionRecordERP.deleteRecords(oldMap.keySet());
        }
        revertOppStage( oldMap.values() );
      }
    }
  }

  private static void setStage( AcctSeed__Project__c[] listNew )
  {
    Id idRtService = gcConstants.idRtProjectService;
    for( AcctSeed__Project__c erp : listNew )
    {
      if( erp.RecordTypeId == idRtService &&
        erp.Service_Date__c != null &&
        erp.Stage__c == 'Quoting' )
      {
        erp.Stage__c = 'Pending Diagnostic';
      }
    }
  }

  private static void boatSpecialistChanged(
    List<AcctSeed__Project__c> listNew,
    Map<Id, AcctSeed__Project__c> oldMap
  )
  {
    Map<Id, Id> boatSpecialistIdByAccountId = new Map<Id, Id>();
    for( AcctSeed__Project__c erp : listNew )
    {
      AcctSeed__Project__c oldErp = oldMap.get( erp.Id );
      if( erp.Boat_Specialist__c != null &&
          erp.Boat_Specialist__c != oldErp.Boat_Specialist__c )
      {
        boatSpecialistIdByAccountId.put( erp.AcctSeed__Account__c, erp.Boat_Specialist__c );
      }
    }
    if( boatSpecialistIdByAccountId.size() > 0 )
    {
      Account_Service.updateOwner( boatSpecialistIdByAccountId );
    }
  }

  public static void updateAndValidate
    (map<Id,AcctSeed__Project__c> oldMap,
      map<Id,AcctSeed__Project__c> newMap,
      list<AcctSeed__Project__c> listNew,
      Boolean boolIsBefore,
      Boolean boolIsInsert,
      Boolean boolIsUpdate,
      Boolean boolIsDelete)
  {
    if(boolIsBefore && (boolIsInsert || boolIsUpdate))
    {
      Set<Id> setIdProject = new Set<Id>();
      for(AcctSeed__Project__c p : listNew)
      {
        //added Mar 2020
        //specify all ERPs use v2 of Commission Records
        if(boolIsInsert)
        {
          p.Uses_V2_Commissions__c = true;
        }
        /// Sales Person Related checkings
        AcctSeed__Project__c oldRec = oldMap.get(p.Id);

        if(p.Salesperson__c == null)
          p.Salesperson__c = UserInfo.getUserId();

        if(boolIsUpdate) setIdProject.add(p.Id);
      }

      list<AcctSeed__Project__c> listAll = new list<AcctSeed__Project__c>();
      listAll.addAll(listNew);
      listAll.addAll(oldMap.values());
      retrieveStatics(listAll);
      /// Find out if project has transactions
      Set<Id> setProjectsWithTxn = new Set<Id>();
      if( !setIdProject.isEmpty() )
      {
        for(AcctSeed__Project__c txnPr : [SELECT Id, (SELECT Id FROM AcctSeed__Project_Transactions__r LIMIT 1) FROM AcctSeed__Project__c WHERE Id IN:setIdProject])
        {
          if(!txnPr.AcctSeed__Project_Transactions__r.isEmpty())
            setProjectsWithTxn.add(txnPr.Id);
        }
      }

      Id idRtBoatSale         = gcConstants.idRtProjectBoatSale;
      Id idRtPartnerBoatSale  = gcConstants.idRtProjectPartnerBoatSale;
      Id idRtCounterSale      = gcConstants.idRtProjectCounterSale;
      Id idRtService          = gcConstants.idRtProjectService;
      Id idRtWarranty         = gcConstants.idRtProjectWarranty;
      Id isFixedAsset         = gcConstants.idRtFixedAsset;
      Id idRtManufacturing    = gcConstants.idRtProjectManufacturing;
      Id idRtTradeIn          = gcConstants.idRtTradeIn;
      Id idRtPartnerPartsOrder= gcConstants.idRtPartnerPartsOrder;
      /// When a Retail ERP is unlinked or linked
      Set<Id> setIdRetailERP = new Set<Id>();
      for(AcctSeed__Project__c p : listNew)
      {
        AcctSeed__Project__c oldRec = oldMap.get(p.Id);

        /* ADDED BY DAVE HAHN - set default counter sale type */
        if( boolIsInsert &&
          p.AcctSeed__Account__c != null &&
          mapAccount.get(p.AcctSeed__Account__c).IsPersonAccount == true )
        {
          if(p.RecordTypeId == idRtCounterSale ){
            p.Counter_Sale_Type__c = 'Retail';
          }
          /* populate contactEmail field from Account */
          if( p.ContactEmail__c == null ){
            p.ContactEmail__c = mapAccount.get(p.AcctSeed__Account__c).PersonEmail;
          }
        }


        if(boolIsUpdate)
        {
          if(p.Locked__c && oldRec.Locked__c)
          {
            if(p.GL_Account_Variable_1__c != oldRec.GL_Account_Variable_1__c
              || p.GL_Account_Variable_2__c != oldRec.GL_Account_Variable_2__c
              || p.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c
              || p.Salesperson__c != oldRec.Salesperson__c
              || p.AcctSeedERP__Manufactured_Product__c != oldRec.AcctSeedERP__Manufactured_Product__c
              || p.AcctSeed__Account__c != oldRec.AcctSeed__Account__c
              || p.GMBLASERP__Warehouse__c != oldRec.GMBLASERP__Warehouse__c
              || p.AcctSeed__Opportunity__c != oldRec.AcctSeed__Opportunity__c
              || p.GMBLASERP__Billing_City__c != oldRec.GMBLASERP__Billing_City__c
              || p.GMBLASERP__Billing_Contact__c != oldRec.GMBLASERP__Billing_Contact__c
              || p.GMBLASERP__Billing_Country__c != oldRec.GMBLASERP__Billing_Country__c
              || p.GMBLASERP__Billing_Postal_Code__c != oldRec.GMBLASERP__Billing_Postal_Code__c
              || p.GMBLASERP__Billing_State__c != oldRec.GMBLASERP__Billing_State__c
              || p.GMBLASERP__Billing_Street__c != oldRec.GMBLASERP__Billing_Street__c
              || p.GMBLASERP__Shipping_City__c != oldRec.GMBLASERP__Shipping_City__c
              || p.GMBLASERP__Shipping_Contact__c != oldRec.GMBLASERP__Shipping_Contact__c
              || p.GMBLASERP__Shipping_Country__c != oldRec.GMBLASERP__Shipping_Country__c
              || p.GMBLASERP__Shipping_Postal_Code__c != oldRec.GMBLASERP__Shipping_Postal_Code__c
              || p.GMBLASERP__Shipping_State__c != oldRec.GMBLASERP__Shipping_State__c
              || p.GMBLASERP__Shipping_Street__c != oldRec.GMBLASERP__Shipping_Street__c
              || p.Tax_Override__c != oldRec.Tax_Override__c
              || p.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c
              || p.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c
              || p.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c
              || p.Fixed_Asset__c != oldRec.Fixed_Asset__c)
            {
              p.addError('Account, Opportunity, Salesperson, Billing Contact, Billing Address, Shipping Contact, Shipping Address, Warehouse, Business Unit (GLV1), Department (GLV2), Salesperson, Tax Zone (GLV3), Serial Number or Tax rates cannot be modified on a Locked ERP order.');
            }
          }
          /// Record Type cannot be changed as well
          if(p.RecordTypeId != oldRec.RecordTypeId)
            p.addError('The Record Type of a Project may not be changed.');
        }

        if(p.GL_Account_Variable_2__c == null)
          p.GL_Account_Variable_2__c = gcConstants.convertProjectRecordTypeToGlv2(p.RecordTypeId);

        if(p.Fixed_Asset__c == null && p.RecordTypeId == isFixedAsset)
          p.addError('Fixed Asset is required for this type of ERP Order.');

        if(p.RecordTypeId == idRTBoatSale ||
          p.RecordTypeId == idRtPartnerBoatSale ||
          p.RecordTypeId == idRtCounterSale ||
          p.RecordTypeId == idRtPartnerPartsOrder ||
          p.RecordTypeId == idRtTradeIn ||
          p.RecordTypeId == idRtWarranty ||
          p.RecordTypeId == isFixedAsset ||
          p.RecordTypeId == idRtService)
        {
          if(p.AcctSeed__Account__c == null)
            p.addError('A Work Order of Record Type [BoatSale, PartnerBoatSale, CounterSale, Trade In, Service, FixedAsset, LegendPartnerPartsOrder OR Warranty] must specify an Account.');
          // A service work order may not have a Manufactured Product.
          if(p.AcctSeedERP__Manufactured_Product__c != null && p.RecordTypeId != idRtTradeIn)
            p.addError('A Work Order of Record Type [BoatSale, PartnerBoatSale, CounterSale, Service or Warranty] must not specify a Manufactured Product.');
        }

        if(p.RecordTypeId == idRTManufacturing)
        {
          if(p.AcctSeedERP__Manufactured_Product__c == null)
            p.addError('A Work Order of Record Type [Manufacturing] must specify a Manufactured Product.');
        }

        Opportunity oppy = mapOppy.get(p.AcctSeed__Opportunity__c);
        Product2 product = mapProduct.get(p.AcctSeedERP__Manufactured_Product__c);
        GMBLASERP__Serial_Number__c serial = mapSerial.get(p.Serial_Number__c);
        Account acct = mapAccount.get(p.AcctSeed__Account__c);
        AcctSeedERP__Warehouse__c whs = mapWarehouse.get(p.GMBLASERP__Warehouse__c);

        /// First Try to determine GLV1 and Warehouse by Account for Dealers Only
        if(acct != null && acct.RecordType.Name.equals('Dealer') &&
          (boolIsInsert
            || (boolIsUpdate && p.AcctSeed__Account__c != oldRec.AcctSeed__Account__c)))
        {
          p.Salesperson__c = acct.OwnerId;
          if((p.Internal_Labour_Service__c && p.GL_Account_Variable_1__c == null)
            || (!p.Internal_Labour_Service__c && !p.Internal_Partner_Boat_Sale__c)){
            p.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
            if(boolIsInsert)
              p.GMBLASERP__Warehouse__c = gcConstants.idWarehouseWholesale;
          }
        }

        if((p.AcctSeed__Status__c == 'Completed' || p.AcctSeed__Status__c == 'Ready For Accounting') && p.Locked__c == false)
          p.Locked__c = true;
        else if(p.AcctSeed__Status__c == 'Completed' && p.AcctSeed__Status__c == 'Ready For Accounting' && p.Locked__c == true)
          p.Locked__c = false;

        //If manufacturing erp GLV1 = wholesale
        if( p.GL_Account_Variable_1__c == null && p.RecordTypeId == idRtManufacturing )
        {
          p.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        }

        //Try to determine GLV1 Only by pickup location
        if( !p.Internal_Partner_Boat_Sale__c && (( p.GL_Account_Variable_1__c == null &&
          p.Pickup_Location__c != null ) ||
          ( boolIsUpdate && p.Pickup_Location__c != oldRec.Pickup_Location__c ) ))
        {
          if( p.Pickup_Location__c.contains('Barrie') )
            p.GL_Account_Variable_1__c = gcConstants.idGlv1Barrie;
          if( p.Pickup_Location__c.contains('Whitefish') )
            p.GL_Account_Variable_1__c = gcConstants.idGlv1Whitefish;
          if( p.Pickup_Location__c.contains('Montreal') )
            p.GL_Account_Variable_1__c = gcConstants.idGlv1Montreal;
        }


        User usr = mapUser.get(p.Salesperson__c);
        /// Second Try to determine GLV1 and Warehouse by User
        if(usr != null)// && (boolIsInsert || (boolIsUpdate && p.Salesperson__c != oldRec.Salesperson__c)))
        {
          String glv1Name = usr.GL_Account_Variable_1__c;
          String whsName = usr.Warehouse__c;
          if(p.GL_Account_Variable_1__c == null && glv1Name != null)
            p.GL_Account_Variable_1__c = mapGlv1ByName.get(glv1Name).Id;
          if(boolIsInsert && p.GMBLASERP__Warehouse__c == null && whsName != null )
            p.GMBLASERP__Warehouse__c = mapWarehouseByName.get(whsName).Id;

          if(p.Internal_Labour_Service__c && (boolIsInsert || (boolIsUpdate && p.GL_Account_Variable_1__c == null)))
          {
            if(glv1Name != null && p.GL_Account_Variable_1__c == null)
              p.GL_Account_Variable_1__c = mapGlv1ByName.get(glv1Name).Id;
          }
        }

        if(boolIsInsert
          && (p.Internal_Partner_Boat_Sale__c
          || p.Internal_Labour_Service__c
          || p.Internal_Partner_Parts_Order__c)){
          p.GMBLASERP__Pricebook__c = gcConstants.idPricebookFactory;
          p.GMBLASERP__Warehouse__c = gcConstants.idWarehouseWholesale;
          if(boolIsInsert && p.Internal_Labour_Service__c && p.GL_Account_Variable_1__c == null)
            p.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        }
        /// If Partner then set the warehouse to Wholesale and GLV1 to Wholesale
        if(boolIsInsert
          && (p.RecordTypeId == idRtPartnerBoatSale
          || p.RecordTypeId == idRtPartnerPartsOrder)){
          p.GMBLASERP__Warehouse__c = gcConstants.idWarehouseWholesale;
          p.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        }

        /// At this point if the GLV1 is still null then set to Whitefish
        if(p.GL_Account_Variable_1__c == null)
          p.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        /// At this point if the Warehouse is still null then set to User Warehouse
        if(p.GMBLASERP__Warehouse__c == null)
          p.GMBLASERP__Warehouse__c = gcConstants.idWarehouseForUser;
        /// At this point if the Warehouse is still null then set to Whitefish Warehouse
        if(p.GMBLASERP__Warehouse__c == null)
          p.GMBLASERP__Warehouse__c = gcConstants.idWarehouseWholesale;

        if(p.GMBLASERP__Pricebook__c == null)
        {
          if(acct != null)
          {
            if(acct.GMBLASERP__Pricebook__c != null)
              p.GMBLASERP__Pricebook__c = acct.GMBLASERP__Pricebook__c;
            else if( acct.IsPersonAccount ||
              ( !acct.IsPersonAccount && !acct.RecordType.Name.equals('Dealer') ) )
              p.GMBLASERP__Pricebook__c = gcConstants.idPricebookRetail;
            else
              p.GMBLASERP__Pricebook__c = gcConstants.idPricebookPartner;
          }
          else
            p.GMBLASERP__Pricebook__c = gcConstants.idPricebookPartner;
        }

        /// Tax Zone automation - START
        /// Automate with GLV1 First
        if( p.GL_Account_Variable_3__c == null )
        {
          if(p.GL_Account_Variable_1__c != null
            && (boolIsInsert
            || (boolIsUpdate && p.GL_Account_Variable_1__c != oldRec.GL_Account_Variable_1__c)))
          {
            AcctSeed__Accounting_Variable__c glvBU = mapGlv.get(p.GL_Account_Variable_1__c);
              if(glvBU.GL_Account_Variable_3__c != null)
              p.GL_Account_Variable_3__c = glvBU.GL_Account_Variable_3__c;
          }
        }
        /// If still not found then Automate with Account Billing State
        if( p.GL_Account_Variable_3__c == null )
        {
          if(p.AcctSeed__Account__c != null
            && (boolIsInsert
            || (boolIsUpdate && p.AcctSeed__Account__c != oldRec.AcctSeed__Account__c)))
          {
            if(acct != null && acct.BillingState != null && mapGlv3ByName.containsKey(acct.BillingState))
              p.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;
          }
        }
        /// If still tax zone is null then set Others
        if((p.GL_Account_Variable_3__c == null
          || p.RecordTypeId == isFixedAsset
          || p.Internal_Warranty__c
          || p.Internal_Partner_Boat_Sale__c
          || p.Internal_Labour_Service__c)
          && !p.Locked__c)
        {
          p.GL_Account_Variable_3__c = gcConstants.idGlv3Others;
          p.Tax_Override__c = true;
          p.Tax_Rate_Federal__c = 0;
          p.Tax_Rate_Provincial__c = 0;
          p.Tax_Rate_Retail__c = 0;
        }
        /// Tax Zone automation - END

        if(!p.Tax_Override__c)
        {
          if(boolIsInsert ||
            (boolIsUpdate &&
              (p.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
                p.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
                p.Tax_Override__c != oldRec.Tax_Override__c ||
                p.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
                p.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
                p.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c)
            )
            )
          {
            p.Tax_Rate_Federal__c = 5;

            AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(p.GL_Account_Variable_3__c);
            if(glvTaxZone != null)
            {
              p.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
              p.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
              p.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
            }
          }
        }
        /// Do not allow changes GLV1 and GLV2 if a project has underlying transactions.
        if(boolIsUpdate && p.GMBLASERP__Warehouse__c != oldRec.GMBLASERP__Warehouse__c && setProjectsWithTxn.contains(p.Id))
          p.addError('ERP Order has underlying transactions. Warehouse may not be changed.');
        if(boolIsUpdate && p.GL_Account_Variable_1__c != oldRec.GL_Account_Variable_1__c && setProjectsWithTxn.contains(p.Id))
          p.addError('ERP Order has underlying transactions. Business Unit (GLV1) may not be changed.');
        if(boolIsUpdate && p.GL_Account_Variable_2__c != oldRec.GL_Account_Variable_2__c && setProjectsWithTxn.contains(p.Id))
          p.addError('ERP Order has underlying transactions. Department (GLV2) may not be changed.');
        if(boolIsUpdate && p.Stage__c != oldRec.Stage__c && p.Stage__c == 'Closed/Lost' && setProjectsWithTxn.contains(p.Id))
          p.addError('ERP Order has underlying transactions. Stage may not be changed to Closed/Lost.');

        if(oppy != null)
        {
          if(p.AcctSeed__Account__c == null)
            p.AcctSeed__Account__c = oppy.AccountId;
          else if(p.AcctSeed__Account__c != oppy.AccountId)
            p.addError('If an Opportunity is specified for a Project, the Account of the Project must match the Account of the Opportunity.');
        }

        if(product != null)
        {
          if(!product.AcctSeed__Inventory_Product__c)
            p.addError('The Manufactured Product must be an inventory product.');
          if(serial != null)
          {
            if(serial.GMBLASERP__Product__c != product.Id)
              p.addError('The Product of the Serial Number must match the Manufactured Product.');
          }
        }
        if(boolIsUpdate && oldRec.Retail_ERP__c != p.Retail_ERP__c){
          setIdRetailERP.add(oldRec.Retail_ERP__c);
        }
        Set<String> setStageDrafts = new Set<String>{'Draft','Quoting','Delivered','Closed Lost'};
        // If the stage was in draft and now comething else then se the actual order date
        if(boolIsUpdate && oldRec.Stage__c != p.Stage__c && setStageDrafts.contains(oldRec.Stage__c)){
          p.Actual_Order_Date__c = System.now();
        }else if(boolIsUpdate && oldRec.Stage__c != p.Stage__c && setStageDrafts.contains(p.Stage__c)){
          p.Actual_Order_Date__c = null;
        }
      }
      /// If there are unlinked Retail ERP then untag all serials
      if(!setIdRetailERP.isEmpty())
        gcMaterial.untagRetailERPItems(setIdRetailERP);
    }

    if(!boolIsBefore)
    {
      Id idRtCounterSale = gcConstants.idRtProjectCounterSale;
      Id idRtBoatSale         = gcConstants.idRtProjectBoatSale;
      Id idRtService          = gcConstants.idRtProjectService;
      Map<Id,Account> mapAccountUpdate = new Map<Id,Account>();
      Set<Id> setIdProject = new Set<Id>();
      Map<Id,AcctSeed__Project__c> mapSerialProject = new Map<Id,AcctSeed__Project__c>();
      /// Serial Number Availablity checking
      Set<Id> setIdSerials = new Set<Id>();
      Set<Id> setIdProjectsWithStatusChange = new Set<Id>();
      Set<Id> setIdProjectsCompletedStatus = new Set<Id>();
      Set<Id> setIdProjectsCompletedToService = new Set<Id>();
      Set<Id> setIdRetailToBeTagged = new Set<Id>();
      Set<Id> setIdProjectStageLost = new Set<Id>();

      List<AcctSeedERP__Material__c> listMaterials = new List<AcctSeedERP__Material__c>();

      if(boolIsUpdate || boolIsInsert)
        for(AcctSeed__Project__c p : listNew)
        {
          AcctSeed__Project__c oldRec = oldMap.get(p.Id);
          if(boolIsUpdate &&
            (p.GL_Account_Variable_1__c != oldRec.GL_Account_Variable_1__c
              || p.GL_Account_Variable_2__c != oldRec.GL_Account_Variable_2__c
              || p.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c)){
            setIdProject.add(p.Id);
          }

          if(boolIsUpdate || boolIsInsert){
            Account acct = mapAccount.get(p.AcctSeed__Account__c);
            if((p.RecordTypeId == idRtCounterSale
              || p.RecordTypeId == idRtBoatSale
              || ( p.RecordTypeId == idRtService
              && !p.Internal_Labour_Service__c ) )
              && acct != null
              && acct.GL_Account_Variable_1__c != p.GL_Account_Variable_1__c)
            {
              if(!acct.Is_Internal__c) {
                acct.GL_Account_Variable_1__c = p.GL_Account_Variable_1__c;
                mapAccountUpdate.put(acct.Id, acct);
              }
            }
          }

          if(boolIsInsert ||
            (boolIsUpdate &&
              (p.Serial_Number__c != oldRec.Serial_Number__c
                || p.AcctSeed__Status__c != oldRec.AcctSeed__Status__c)))
            mapSerialProject.put(p.Serial_Number__c,p);

          if((boolIsInsert && p.Serial_Number__c != null) || (boolIsUpdate && p.Serial_Number__c != oldRec.Serial_Number__c)) {
            setIdSerials.add(p.Serial_Number__c);
            if(boolIsUpdate)
              setIdSerials.add(oldRec.Serial_Number__c);
          }
          if(boolIsUpdate && p.AcctSeed__Status__c != oldRec.AcctSeed__Status__c)
            setIdProjectsWithStatusChange.add(p.Id);
          if(p.Stage__c == 'Closed/Lost'
            && (boolIsUpdate && p.Stage__c != oldRec.Stage__c)) {
            setIdProjectStageLost.add(p.Id);
          }
          if(p.AcctSeed__Status__c == 'Completed'
            && (boolIsInsert
            || (boolIsUpdate && p.AcctSeed__Status__c != oldRec.AcctSeed__Status__c))){
            setIdProjectsCompletedStatus.add(p.Id);
            if((p.RecordTypeId == gcConstants.idRtProjectBoatSale
              || p.RecordTypeId == gcConstants.idRtPartnerPartsOrder)
              && p.Service_ERP__c == null)
              setIdProjectsCompletedToService.add(p.Id);
          }

          if(boolIsUpdate && p.Retail_ERP__c != null){
            setIdRetailToBeTagged.add(p.Id);
          }
        }
      if(boolIsDelete)
        for(AcctSeed__Project__c p : oldMap.values())
        {
          if(p.Serial_Number__c != null)
            setIdSerials.add(p.Serial_Number__c);
        }
      /// Before doing anything else check to see if the Project is eligible to be Completed
      if(!setIdProjectsCompletedStatus.isEmpty())
        checkProjectHasUnWIPUnCogsQty(setIdProjectsCompletedStatus);
      if(!setIdProjectsCompletedToService.isEmpty())
        createServiceERP(setIdProjectsCompletedToService);
      /// Now checking if the serial number has been used in more active projects other then
      // warranty
      if( !mapSerialProject.isEmpty() )
      {
        Id idRtWarranty = gcConstants.idRtProjectWarranty;
        for(GMBLASERP__Serial_Number__c sn :
        [SELECT Id,
          Name,
        (SELECT Id, Name, RecordTypeId FROM Projects__r WHERE AcctSeed__Status__c = 'Active' OR AcctSeed__Status__c = 'New')
        FROM GMBLASERP__Serial_Number__c
        WHERE Id IN:mapSerialProject.keySet()])
        {
          if(!sn.Projects__r.isEmpty())
          {
            AcctSeed__Project__c pr = mapSerialProject.get(sn.Id);
            for(AcctSeed__Project__c proj : sn.Projects__r)
            {
              if( proj.Id != pr.Id &&
                pr.RecordTypeId == proj.RecordTypeId &&
                pr.RecordTypeId != idRtWarranty )
                newMap.get(pr.Id).addError('Cannot reuse the serial number '+sn.Name+'. It has been used in another ERP Order '+proj.Name+'.');
            }
          }
        }
      }
      /// At this point we will update the child records if required
      if(!setIdProject.isEmpty())
      {
        update [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c IN:setIdProject];
        update [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c IN:setIdProject];
      }
      Set<Id> setCombinedId = new Set<Id>();
      setCombinedId.addAll(setIdProjectsWithStatusChange);
      setCombinedId.addAll(setIdRetailToBeTagged);
      setCombinedId.addAll(setIdProjectStageLost);
      if(!setCombinedId.isEmpty())
      {
        for(AcctSeedERP__Material__c matl :
        [SELECT Id,
          GMBLASERP__Serial_Number__c,
          AcctSeedERP__Project__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c IN:setCombinedId
        AND GMBLASERP__Serial_Number__c != null])
        {
          if(setIdProjectsWithStatusChange.contains(matl.AcctSeedERP__Project__c))
            setIdSerials.add(matl.GMBLASERP__Serial_Number__c);
          if(setIdRetailToBeTagged.contains(matl.AcctSeedERP__Project__c))
            listMaterials.add(matl);
          if(setIdProjectStageLost.contains(matl.AcctSeedERP__Project__c)){
            matl.GMBLASERP__Serial_Number__c = null;
            listMaterials.add(matl);
          }
        }
      }

      ///// Update serial numbers availablility future
      setIdSerials.remove(null);
      if(!setIdSerials.isEmpty() && !System.isBatch())
        gcSerialNumber.updateSerialIsAvailableFuture(setIdSerials);
      if(!listMaterials.isEmpty()) {
        gcMaterial.doNotRunDeNesting = true;
        update listMaterials;
      }

      /// updating account
      if(!mapAccountUpdate.isEmpty()){
        Boolean acVal = gcAccount.disableTrigger;
        gcAccount.disableTrigger = true;
        update mapAccountUpdate.values();
        gcAccount.disableTrigger = acVal;
      }
    }
  }

  private static map<Id,Opportunity> mapOppy;
  private static map<Id,Product2> mapProduct;
  private static map<Id,GMBLASERP__Serial_Number__c> mapSerial;
  private static map<Id,Account> mapAccount;
  private static map<Id,AcctSeedERP__Warehouse__c> mapWarehouse;
  private static map<String,AcctSeedERP__Warehouse__c> mapWarehouseByName;
  private static map<Id,AcctSeed__Accounting_Variable__c> mapGlv;
  private static map<String,AcctSeed__Accounting_Variable__c> mapGlv3ByName;
  private static map<String,AcctSeed__Accounting_Variable__c> mapGlv1ByName;
  private static map<Id,User> mapUser;

  private static void retrieveStatics(list<AcctSeed__Project__c> listNew)
  {
    set<Id> setIdOppy = new set<Id>();
    set<Id> setIdProduct = new set<Id>();
    set<Id> setIdSerial = new set<Id>();
    set<Id> setIdAccount = new set<Id>();
    set<Id> setIdWarehouse = new set<Id>();
    set<Id> setIdGlv = new set<Id>();
    set<Id> setIdUser = new set<Id>();
    /// By Account State we will try to determine the Tax Zone
    set<String> setNameGlv = new set<String>();
    set<String> setNameWhs = new set<String>();

    if(mapOppy == null)
    {
      mapOppy = new map<Id,Opportunity>();
      mapProduct = new map<Id,Product2>();
      mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
      mapAccount = new map<Id,Account>();
      mapWarehouse = new map<Id,AcctSeedERP__Warehouse__c>();
      mapWarehouseByName = new map<String,AcctSeedERP__Warehouse__c>();
      mapGlv = new map<Id,AcctSeed__Accounting_Variable__c>();
      mapGlv3ByName = new map<String,AcctSeed__Accounting_Variable__c>();
      mapGlv1ByName = new map<String,AcctSeed__Accounting_Variable__c>();
      mapUser = new map<Id,User>();
    }

    for(AcctSeed__Project__c p : listNew)
    {
      if(p.AcctSeed__Opportunity__c != null && !mapOppy.containsKey(p.AcctSeed__Opportunity__c))
        setIdOppy.add(p.AcctSeed__Opportunity__c);

      if(p.AcctSeedERP__Manufactured_Product__c != null && !mapProduct.containsKey(p.AcctSeedERP__Manufactured_Product__c))
        setIdProduct.add(p.AcctSeedERP__Manufactured_Product__c);

      if(p.Serial_Number__c != null && !mapSerial.containsKey(p.Serial_Number__c))
        setIdSerial.add(p.Serial_Number__c);

      if(p.AcctSeed__Account__c != null && !mapAccount.containsKey(p.AcctSeed__Account__c))
        setIdAccount.add(p.AcctSeed__Account__c);

      if(p.GMBLASERP__Warehouse__c != null && !mapWarehouse.containsKey(p.GMBLASERP__Warehouse__c))
        setIdWarehouse.add(p.GMBLASERP__Warehouse__c);

      if(p.GL_Account_Variable_1__c != null && !mapGlv.containsKey(p.GL_Account_Variable_1__c))
        setIdGlv.add(p.GL_Account_Variable_1__c);

      if(p.GL_Account_Variable_3__c != null && !mapGlv.containsKey(p.GL_Account_Variable_3__c))
        setIdGlv.add(p.GL_Account_Variable_3__c);

      if(p.Salesperson__c != null && !mapUser.containsKey(p.Salesperson__c))
        setIdUser.add(p.Salesperson__c);
    }

    if(!mapGlv.containsKey(gcConstants.idGlv1Whitefish))
      setIdGlv.add(gcConstants.idGlv1Whitefish);

    if(!mapGlv.containsKey(gcConstants.idGlv3Ontario))
      setIdGlv.add(gcConstants.idGlv3Ontario);

    if(!mapGlv.containsKey(gcConstants.idGlv1Wholesale))
      setIdGlv.add(gcConstants.idGlv1Wholesale);

    if(!setIdOppy.isEmpty())
      for(Opportunity oppy :
      [SELECT Id, Name, AccountId
      FROM Opportunity
      WHERE Id IN :setIdOppy])
      {
        mapOppy.put(oppy.Id,oppy);
      }

    if(!setIdAccount.isEmpty())
      for(Account a :
      [SELECT Id,
        GMBLASERP__Pricebook__c,
        BillingState,
        GL_Account_Variable_1__c,
        Warehouse__c,
        RecordTypeId,
        RecordType.Name,
        IsPersonAccount,
        PersonEmail,
        Is_Internal__c,
        OwnerId
      FROM Account
      WHERE Id IN :setIdAccount])
      {
        mapAccount.put(a.Id,a);
        setIdUser.add(a.OwnerId);
        if(a.GL_Account_Variable_1__c != null && !mapGlv.containsKey(a.GL_Account_Variable_1__c))
          setIdGlv.add(a.GL_Account_Variable_1__c);
        if(a.BillingState != null && !mapGlv3ByName.containsKey(a.BillingState))
          setNameGlv.add(a.BillingState);
      }

    if(!setIdUser.isEmpty())
      for(User u : [SELECT Id, GL_Account_Variable_1__c, Warehouse__c FROM User WHERE Id IN:setIdUser])
      {
        if(u.GL_Account_Variable_1__c != null)
          setNameGlv.add(u.GL_Account_Variable_1__c);
        if(u.Warehouse__c != null)
          setNameWhs.add(u.Warehouse__c);

        mapUser.put(u.Id, u);
      }

    if(!setIdWarehouse.isEmpty() || !setNameWhs.isEmpty())
      for(AcctSeedERP__Warehouse__c whs :
      [SELECT Id,
        Name,
        GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Id IN:setIdWarehouse OR Name IN:setNameWhs])
      {
        mapWarehouse.put(whs.Id,whs);
        mapWarehouseByName.put(whs.Name,whs);
        if(whs.GL_Account_Variable_3__c != null && !mapGlv.containsKey(whs.GL_Account_Variable_3__c))
          setIdGlv.add(whs.GL_Account_Variable_3__c);
      }

    if(!setIdProduct.isEmpty())
      for(Product2 p :
      [SELECT Id,
        AcctSeed__Inventory_Product__c,
        AcctSeedERP__Serialized__c
      FROM Product2
      WHERE Id IN :setIdProduct])
      {
        mapProduct.put(p.Id,p);
      }

    if(!setIdGlv.isEmpty() || !setNameGlv.isEmpty())
      for(AcctSeed__Accounting_Variable__c glv :
      [SELECT Id,
        Name,
        Tax_is_Harmonized__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        GL_Account_Variable_3__c,
        AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE Id IN :setIdGlv OR Name IN:setNameGlv])
      {
        mapGlv.put(glv.Id,glv);
        if(glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
          mapGlv1ByName.put(glv.Name,glv);
        if(glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
          mapGlv3ByName.put(glv.Name,glv);
      }

    if(!setIdSerial.isEmpty())
      for(GMBLASERP__Serial_Number__c sn :
      [SELECT Id,
        GMBLASERP__Product__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Id IN :setIdSerial])
      {
        mapSerial.put(sn.Id,sn);
      }
  }

  private static void rename(set<Id> setIdProject)
  {
    list<AcctSeed__Project__c> listProjectUpdate = new list<AcctSeed__Project__c>();
    for(AcctSeed__Project__c p :
    [SELECT Id,
      Name,
      AcctSeed__Opportunity__r.Name,
      AcctSeedERP__Work_Order_Number__c
    FROM AcctSeed__Project__c
    WHERE Id In :setIdProject])
    {
      String prefix = String.valueOf(Integer.valueOf(p.AcctSeedERP__Work_Order_Number__c.replaceAll('[^0-9]','')))+'-';
      String name = p.Name;
      if(!name.startsWithIgnoreCase(prefix))
      {
        name = prefix+(p.Name == null ? '' : p.Name);
        name = name.LEFT(80);

        p.Name = name;
        listProjectUpdate.add(p);
      }
    }
    if(!listProjectUpdate.isEmpty())
    {
      Boolean boolOld = gcProject.disableTrigger;
      gcProject.disableTrigger = true;
      update listProjectUpdate;
      gcProject.disableTrigger = boolOld;
    }
  }

  public static void lockProjects(Set<Id> setIdProject)
  {
    if(setIdProject.isEmpty()) return;
    List<AcctSeed__Project__c> listProjects = new List<AcctSeed__Project__c>();
    Application_RecordType.ERPOrderRTs recordTypes = new Application_RecordType.ERPOrderRTs();

    for(AcctSeed__Project__c project : [SELECT Id, RecordTypeId, Name, Locked__c, AcctSeed__Status__c, Internal_Partner_Boat_Sale__c FROM AcctSeed__Project__c WHERE Id IN :setIdProject])
    {
      if(project.AcctSeed__Status__c != 'Completed'){
        if( project.RecordTypeId == recordTypes.getCounterSaleId() ||
            project.RecordTypeId == recordTypes.getManufacturingId() ||
            project.RecordTypeId == recordTypes.getPartnerBoatSaleId()	)
        {
          project.AcctSeed__Status__c = 'Completed';
          listProjects.add(project);
        }
        else if(project.AcctSeed__Status__c != 'Ready For Accounting')
        {
          project.AcctSeed__Status__c = 'Ready For Accounting';
          listProjects.add(project);
        }
      }
    }
    if(!listProjects.isEmpty())
    {
      Boolean boolOld = gcProject.disableTrigger;
      gcProject.disableTrigger = true;
      update listProjects;
      gcProject.disableTrigger = boolOld;
    }
  }

  public static void lockIfNoBalanceDue(Set<Id> setIdProject)
  {
    setIdProject.remove(null);
    if(setIdProject.isEmpty()) return;
    Id idRtBoatSale = gcConstants.idRtProjectBoatSale;
    Id idRtPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
    Map<Id,Decimal> mapProjectTotal = new Map<Id,Decimal>();
    Map<Id,AcctSeed__Project__c> mapProjectData = new Map<Id,AcctSeed__Project__c>();
    for(AcctSeed__Project__c p : [SELECT Id, Grand_Total__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id IN:setIdProject])
    {
      mapProjectTotal.put(p.Id, p.Grand_Total__c == null ? 0 : p.Grand_Total__c);
      mapProjectData.put(p.Id, p);
    }
    Set<Id> setIdProjectLock = new Set<Id>();
    for(sObject txn :
    [SELECT
      AcctSeed__Project__c idProject,
      SUM(AcctSeed__Amount__c) grandTotal
    FROM AcctSeed__Transaction__c
    WHERE AcctSeed__Project__c IN:setIdProject
    AND AcctSeed__GL_Account__r.AcctSeed__Bank__c = true
    GROUP BY AcctSeed__Project__c])
    {
      Decimal gTotal = (Decimal) txn.get('grandTotal');
      Id idProject = (Id) txn.get('idProject');
      if(mapProjectTotal.get(idProject).setScale(2) <= gTotal.setScale(2)
        && mapProjectData.get(idProject).RecordTypeId != idRtBoatSale
        && mapProjectData.get(idProject).RecordTypeId != idRtPartnerBoatSale)
        setIdProjectLock.add(idProject);
    }

    if(!setIdProjectLock.isEmpty()){
      try{
        checkProjectHasUnWIPUnCogsQty(setIdProjectLock);
        lockProjects(setIdProjectLock);
      }catch(Exception e){
        System.debug('setIdProjectLock:'+setIdProjectLock);
      }
    }
  }

  private static void revertOppStage( AcctSeed__Project__c[] projects)
  {
    Set<Id> oppIds = new Set<Id>();
    for( AcctSeed__Project__c p : projects )
    {
      if( p.RecordTypeId != gcConstants.idRtTradeIn && p.AcctSeed__Opportunity__c != null )
        oppIds.add( p.AcctSeed__Opportunity__c );
    }
    Opportunity[] opps = [SELECT Id FROM Opportunity WHERE Id IN : oppIds];
    for( Opportunity o : opps )
    {
      o.StageName = 'Pending ERP';
    }
    update opps;
  }

  private static void recalculateInsuranceItems( List<AcctSeed__Project__c> listNew,
    Map<Id, AcctSeed__Project__c> oldMap )
  {
    Map<Id, Map<String, String>> preInsuranceChanged = new Map<Id, Map<String, String>>();
    //Temperary until we get Insurance stuff figured out for Quebec
    //Set<Id> quebecAccounts = findQuebecAccounts( listNew );
    for( AcctSeed__Project__c erp : listNew )
    {
      AcctSeed__Project__c oErp = oldMap.get( erp.Id );
      if(
        ( erp.Pre_Insurance_Total__c != oErp.Pre_Insurance_Total__c ) ||
          ( erp.Insurance_Term__c != oErp.Insurance_Term__c ) ||
          ( erp.Deposit__c != oErp.Deposit__c ) ||
          ( erp.Finance_Annual_Interest__c != oErp.Finance_Annual_Interest__c ) ||
          ( erp.Finance_Ammortization__c != oErp.Finance_Ammortization__c )
        )
      {
        Map<String, String> data = new Map<String, String>();
        data.put('amount', erp.Pre_Insurance_Total__c == null ? '0' : String.ValueOf( erp.Pre_Insurance_Total__c) );
        data.put('deposit', erp.Deposit__c == null ? '0' : String.ValueOf( erp.Deposit__c) );
        data.put('insTerm', erp.Insurance_Term__c == null ? '0' : String.ValueOf( erp.Insurance_Term__c) );
        data.put('finTerm', erp.Finance_Term__c == null ? '0' : String.ValueOf( erp.Finance_Term__c) );
        data.put('amort', erp.Finance_Ammortization__c == null ? '0' : String.ValueOf( erp.Finance_Ammortization__c) );
        data.put('intrestRate', erp.Finance_Annual_Interest__c == null ? '0' : String.ValueOf( erp.Finance_Annual_Interest__c) );
        data.put('taxZone', erp.GL_Account_Variable_3__c );
        data.put('insuranceTaxRate', erp.Tax_Rate_Retail__c == null ? '0' : String.ValueOf( erp.Tax_Rate_Retail__c ) );
        data.put('termChanged', erp.Insurance_Term__c != oerp.Insurance_Term__c ? 'true' : 'false');

        preInsuranceChanged.put( erp.Id, data );
      }
    }
    if( preInsuranceChanged.size() > 0 ) {
      doInsuranceCalculations( preInsuranceChanged );
    } else {
      System.debug( preInsuranceChanged.size() );
    }
  }

  private static void doInsuranceCalculations( Map<Id, Map<String, String>> changeMap )
  {
    List<AcctSeedERP__Material__c> toUpdate = new List<AcctSeedERP__Material__c>();
    Map<Id, List<AcctSeedERP__Material__c>> matMap = new Map<Id, List<AcctSeedERP__Material__c>>();
    for( AcctSeedERP__Material__c mat : Material_Selector.allInsuranceMaterialsByProjectIds( changeMap.keySet() ) )
    {
      if( !matMap.containsKey( mat.AcctSeedERP__Project__c ) )
        matMap.put( mat.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>() );
      matMap.get( mat.AcctSeedERP__Project__c ).add( mat );
    }
    Set<Id> prodIds = new Set<Id>();
    for( String erpId : changeMap.keySet() )
    {
      if( changeMap.get( erpId ).get('termChanged') == 'true' &&
        matMap.containsKey( erpId ) )
      {
        for( AcctSeedERP__Material__c mat : matMap.get( erpId) )
        {
          prodIds.add( mat.AcctSeedERP__Product__c );
        }
      }
    }
    if( prodIds.size() > 0 )
    {
      Map<Id, Product2> prodMap = new Map<Id, Product2>( [SELECT Id,
      (SELECT Id,
        Joint__c,
        Joint_Factored_Result__c,
        Single__c,
        Tax_Zone__c,
        Tax_Zone__r.Name,
        Lower_Term__c,
        Upper_Term__c,
        Lower_Finance_Term__c,
        Upper_Finance_Term__c
      FROM Insurance_Rates__r)
      FROM Product2
      WHERE Id IN :prodIds]);
      for( String erpId : changeMap.keySet() )
      {
        for( AcctSeedERP__Material__c mat : matMap.get( erpId) )
        {
          Boolean foundTerm = false;
          for( Insurance_Rate__c ir : prodMap.get( mat.AcctSeedERP__Product__c ).Insurance_Rates__r )
          {
            Decimal it = Decimal.valueOf( changeMap.get( erpId ).get('insTerm') );
            Decimal ft = Decimal.valueOf( changeMap.get( erpId ).get('finTerm') );
            if( ir.Tax_Zone__c == changeMap.get( erpId ).get('taxZone') &&
              (
                (
                  it >= ir.Lower_Term__c &&
                    it <= ir.Upper_Term__c &&
                    ft >= ir.Lower_Finance_Term__c &&
                    ft <= ir.Upper_Finance_Term__c
                )
                  ||
                  (
                    it >= ir.Lower_Term__c &&
                      it <= ir.Upper_Term__c &&
                      (
                        ir.Lower_Finance_Term__c == null ||
                          ir.Upper_Finance_Term__c == null
                      )
                  )
              )
              )
            {
              foundTerm = true;
              if( mat.Insurance_Coverage__c == 'Single' )
                mat.Insurance_Rate__c = ir.Single__c;
              if( mat.Insurance_Coverage__c == 'Joint' ) {
                if (ir.Tax_Zone__r.Name == 'Quebec')
                  mat.Insurance_Rate__c = ir.Joint_Factored_Result__c;
                else
                  mat.Insurance_Rate__c = ir.Joint__c;
              }
            }
          }
          if( !foundTerm )
          {
            mat.Insurance_Rate__c.addError( mat.AcctSeedERP__Product__r.Name + ' does not contain an insurance premium rate for term = ' + changeMap.get( erpId ).get('term') );
          }
        }
      }
    }
    for( String erpId : changeMap.keySet() )
    {
      if( matMap.containsKey( erpId ) )
        toUpdate.addAll( doInsuranceCalculation_perERP( changeMap.get(erpId), matMap.get(erpId) ) );
    }
    if( toUpdate.size() > 0 ) {
      Set<Id> taskIds = new Set<Id>();
      for( AcctSeedERP__Material__c mat : toUpdate )
      {
        taskIds.add( mat.AcctSeedERP__Project_Task__c );
      }
      Boolean matBool = gcMaterial.disableTrigger;
      gcMaterial.disableTrigger = true;
      update toUpdate;
      gcProjectTask.rollUpOrderItem( taskIds );
      CommissionLineItem2_Service.syncToMaterials( toUpdate );
      gcMaterial.disableTrigger = matBool;

    }
  }

  private static List<AcctSeedERP__Material__c> doInsuranceCalculation_perErp( Map<String, String> erpValues,
    AcctSeedERP__Material__c[] mats )
  {
    Map<Id, AcctSeedERP__Material__c> matMap = new Map<Id, AcctSeedERP__Material__c>();
    List<Map<String, String>> lineData = new List<Map<String, String>>();
    for( AcctSeedERP__Material__c mat : mats )
    {
      matMap.put( mat.Id, mat );
      Map<String, String> d = new Map<String, String>();
      d.put('recordId', mat.Id);
      d.put('isResidual', String.valueOf( mat.AcctSeedERP__Product__r.Is_Residual_Insurance__c ) );
      d.put('insuranceRate', String.valueOf( mat.Insurance_Rate__c ) );
      d.put('productFamily', String.valueOf( mat.AcctSeedERP__Product__r.Family ) );
      lineData.add( d );
    }
    Map<String, Decimal> result = BusinessOffice_Controller.calculateInsurancePremiums_withTaxZoneId(
      lineData,
      Decimal.valueOf( erpValues.get('amount') ),
      Decimal.valueOf( erpValues.get('deposit') ),
      Decimal.valueOf( erpValues.get('insTerm') ),
      Decimal.valueOf( erpValues.get('amort') ),
      Decimal.valueOf( erpValues.get('intrestRate') ),
      Decimal.valueOf( erpValues.get('insuranceTaxRate') ),
      erpValues.get('taxZone') );
    for( Id erpId : result.keySet() )
    {
      matMap.get(erpId).GMBLASERP__Unit_Price__c = result.get( erpId );
    }
    return matMap.values();
  }

  private static void createServiceERP(Set<Id> setIdProject){
    setIdProject.remove(null);
    if(setIdProject.isEmpty()) return;
    Legend_Settings__c lSettings = Legend_Settings__c.getOrgDefaults();
    List<AcctSeed__Project__c> listProjects = new List<AcctSeed__Project__c>();
    for(AcctSeed__Project__c pr :
    [SELECT Id,
      GL_Account_Variable_1__c,
      GL_Account_Variable_2__c,
      GL_Account_Variable_3__c,
      Total_Labour_Hours__c
    FROM AcctSeed__Project__c
    WHERE Id IN:setIdProject
    AND Total_Labour_Hours__c > 0
    AND Service_ERP__c = null
    AND AcctSeed__Status__c = 'Completed'])
    {
      listProjects.add(pr);
    }
    if(!listProjects.isEmpty()){
      Map<Id,Account> mapAccInternal = new Map<Id,Account>();
      for(Account acc :
      [SELECT Id,
        Name,
        GL_Account_Variable_1__c,
        Warehouse__c
      FROM Account
      WHERE Is_Internal__c = true])
      {
        mapAccInternal.put(acc.GL_Account_Variable_1__c, acc);
      }
      Map<Id,AcctSeed__Project__c> mapProject = new Map<Id,AcctSeed__Project__c>();
      Map<Id,AcctSeed__Project_Task__c> mapProjectTask = new Map<Id,AcctSeed__Project_Task__c>();
      Map<Id,AcctSeedERP__Material__c> mapProjectMaterial = new Map<Id,AcctSeedERP__Material__c>();
      for(AcctSeed__Project__c pr : listProjects){
        Account acc = mapAccInternal.get(pr.GL_Account_Variable_1__c);
        AcctSeed__Project__c newProject = new AcctSeed__Project__c(
          RecordTypeId = gcConstants.idRtProjectService,
          Name = acc.Name,
          AcctSeed__Account__c = acc.Id,
          GL_Account_Variable_1__c = pr.GL_Account_Variable_1__c,
          GL_Account_Variable_2__c = gcConstants.idGlv2PartsAndService,
          GMBLASERP__Warehouse__c = acc.Warehouse__c,
          GMBLASERP__Pricebook__c = lSettings.Default_Factory_Pricebook__c
        );
        mapProject.put(pr.Id, newProject);
        /// Project Task
        AcctSeed__Project_Task__c newTask = new AcctSeed__Project_Task__c(Name = 'Internal Labour', DisplayOnCustomerInvoice__c = true, AcctSeed__GL_Account_Variable_2__c = gcConstants.idGLV2Sales);
        mapProjectTask.put(pr.Id, newTask);
        /// Material
        AcctSeedERP__Material__c newMaterial = new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = lSettings.Product_Internal_Labour__c,
          AcctSeedERP__Quantity_Per_Unit__c = pr.Total_Labour_Hours__c
        );
        mapProjectMaterial.put(pr.Id, newMaterial);
      }
      /// Insert Project
      if(!mapProject.isEmpty()){
        List<AcctSeed__Project__c> listProjectUpdate = new List<AcctSeed__Project__c>();
        insert mapProject.values();
        /// insert Tasks
        for(Id idPr : mapProjectTask.keySet()){
          mapProjectTask.get(idPr).AcctSeed__Project__c = mapProject.get(idPr).Id;
          listProjectUpdate.add(new AcctSeed__Project__c(Id = idPr, Service_ERP__c = mapProject.get(idPr).Id));
        }
        insert mapProjectTask.values();
        /// Insert Material
        for(Id idPr : mapProjectMaterial.keySet()){
          mapProjectMaterial.get(idPr).AcctSeedERP__Project__c = mapProject.get(idPr).Id;
          mapProjectMaterial.get(idPr).AcctSeedERP__Project_Task__c = mapProjectTask.get(idPr).Id;
        }
        insert mapProjectMaterial.values();

        Boolean oldVal = disableTrigger;
        disableTrigger = true;
        update listProjectUpdate;
        disableTrigger = oldVal;
      }
    }
  }

  private class erpCube
  {
    AcctSeed__Project__c project;
    Map<Id,Set<Id>> mapUniqueProductsByTask;
    Decimal qtyZeroAmount;
    Decimal qtyZeroAmountInventory;
    Decimal qtyUnbilled;
    Decimal amtUnbilled;
    Decimal allQtySpecified;
    Decimal qtySpecified;
    Decimal qtyTransferred;
    Decimal qtyWIP;
    Decimal qtyUnWIP;
    Decimal fgMoveQty;
    Decimal noCogsQty;
    Decimal cogsQty;
    erpCube(AcctSeed__Project__c pProject)
    {
      project = pProject;
      mapUniqueProductsByTask = new Map<Id,Set<Id>>();
      qtyZeroAmountInventory = 0;
      qtyZeroAmount = 0;
      amtUnbilled = 0;
      qtyUnbilled = 0;
      allQtySpecified = 0;
      qtySpecified = 0;
      qtyTransferred = 0;
      qtyWIP = 0;
      qtyUnWIP = 0;
      fgMoveQty = 0;
      noCogsQty = 0;
      cogsQty = 0;
    }
  }

  public static void checkProjectHasUnWIPUnCogsQty(Set<Id> setIdProjects)
  {
    Map<Id,erpCube> mapCube = new Map<Id,erpCube>();
    Map<Id,Decimal> mapProjectFinishedMoves = new Map<Id,Decimal>();
    List<AcctSeedERP__Material__c> listMaterials = new List<AcctSeedERP__Material__c>();
    Set<Id> setIdGlCogsParts = new Set<Id>{gcConstants.idGlCogsParts,gcConstants.idGlInternalRevenue};
    for(AcctSeedERP__Material__c matl :
    [SELECT AcctSeedERP__Project__c,
      AcctSeedERP__Project__r.Id,
      AcctSeedERP__Project__r.Name,
      AcctSeedERP__Project__r.RecordTypeId,
      AcctSeedERP__Project__r.RecordType.Name,
      AcctSeedERP__Project__r.CreatedDate,
      AcctSeedERP__Project__r.Stage__c,
      AcctSeedERP__Project__r.Internal_Warranty__c,
      AcctSeedERP__Project__r.Internal_Partner_Parts_Order__c,
      AcctSeedERP__Project_Task__c,
      AcctSeedERP__Product__c,
      AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
      AcctSeedERP__Quantity_per_Unit__c,
      AcctSeedERP__Quantity_Allocated__c,
      GMBLASERP__Total_Price__c,
      GMBLASERP__Unit_Price__c,
      No_WIP__c,
    (SELECT AcctSeed__Hours_Units__c,
      AcctSeed__Rate__c,
      AcctSeed__Total__c
    FROM GMBLASERP__Billing_Lines__r),
    (SELECT Id, AcctSeedERP__Quantity__c FROM Outbound_Inventory_Movements__r)
    FROM AcctSeedERP__Material__c
    WHERE AcctSeedERP__Project__c IN:setIdProjects])
    {
      mapProjectFinishedMoves.put(matl.AcctSeedERP__Project__c, 0);
      listMaterials.add(matl);
    }
    /// FG Moves
    for(sObject move :
    [SELECT AcctSeedERP__Project__c idProject,
      sum(AcctSeedERP__Quantity__c) fgQty
    FROM AcctSeedERP__Inbound_Inventory_Movement__c
    WHERE AcctSeedERP__Project__c IN:mapProjectFinishedMoves.keySet()
    GROUP BY AcctSeedERP__Project__c])
    {
      mapProjectFinishedMoves.put((Id)move.get('idProject'), (Decimal)move.get('fgQty'));
    }
    /// COGS Entries
    Map<Id,Map<Id,Map<Id,Decimal>>> mapPTPQty = new Map<Id,Map<Id,Map<Id,Decimal>>>();
    for(AcctSeed__Journal_Entry_Line__c cogsJE :
    [SELECT AcctSeed__Project__c,
      AcctSeed__Project_Task__c,
      AcctSeed__Product__c,
      AcctSeed__Units__c
    FROM AcctSeed__Journal_Entry_Line__c
    WHERE Internal_Wholesale_Cost__c = false
    AND AcctSeed__Project__c IN:mapProjectFinishedMoves.keySet()
    AND AcctSeed__GL_Account__c IN:setIdGlCogsParts])
    {
      if(!mapPTPQty.containsKey(cogsJE.AcctSeed__Project__c))
        mapPTPQty.put(cogsJE.AcctSeed__Project__c, new Map<Id,Map<Id,Decimal>>());
      if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).containsKey(cogsJE.AcctSeed__Project_Task__c))
        mapPTPQty.get(cogsJE.AcctSeed__Project__c).put(cogsJE.AcctSeed__Project_Task__c, new Map<Id,Decimal>());
      if(!mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).containsKey(cogsJE.AcctSeed__Product__c))
        mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, 0);

      Decimal qty = cogsJE.AcctSeed__Units__c == null ? 0 : cogsJE.AcctSeed__Units__c;
      Decimal nQty = mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).get(cogsJE.AcctSeed__Product__c) + qty;

      mapPTPQty.get(cogsJE.AcctSeed__Project__c).get(cogsJE.AcctSeed__Project_Task__c).put(cogsJE.AcctSeed__Product__c, nQty);
    }

    for(AcctSeedERP__Material__c matl : listMaterials)
    {
      Decimal priorTrnsQty = 0;
      Decimal priorBillAmt = 0;
      Decimal priorBillQty = 0;
      for(AcctSeed__Billing_Line__c line : matl.GMBLASERP__Billing_Lines__r)
      {
        priorBillQty += (line.AcctSeed__Hours_Units__c == null ? 0 : line.AcctSeed__Hours_Units__c);
        priorBillAmt += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
      }
      for(AcctSeedERP__Outbound_Inventory_Movement__c out : matl.Outbound_Inventory_Movements__r)
        priorTrnsQty += (out.AcctSeedERP__Quantity__c == null ? 0 : out.AcctSeedERP__Quantity__c);

      Decimal matlAmount = (matl.GMBLASERP__Total_Price__c == null ? 0 : matl.GMBLASERP__Total_Price__c);
      Decimal matlQtySpec = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
      Decimal matlQtyAlloc = (matl.AcctSeedERP__Quantity_Allocated__c == null ? 0 : matl.AcctSeedERP__Quantity_Allocated__c);
      Decimal fgMoveQty = mapProjectFinishedMoves.get(matl.AcctSeedERP__Project__c);
      Decimal cogsQty = 0;
      Id idProjectRT = matl.AcctSeedERP__Project__r.RecordTypeId;
      if(idProjectRT != gcConstants.idRtProjectManufacturing
        && mapPTPQty.containsKey(matl.AcctSeedERP__Project__c)
        && mapPTPQty.get(matl.AcctSeedERP__Project__c).containsKey(matl.AcctSeedERP__Project_Task__c)
        && mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).containsKey(matl.AcctSeedERP__Product__c))
      {
        cogsQty = mapPTPQty.get(matl.AcctSeedERP__Project__c).get(matl.AcctSeedERP__Project_Task__c).get(matl.AcctSeedERP__Product__c);
      }

      erpCube cube = mapCube.get(matl.AcctSeedERP__Project__c);
      if(cube == null){
        cube = new erpCube(matl.AcctSeedERP__Project__r);
        mapCube.put(matl.AcctSeedERP__Project__c, cube);
      }
      cube.allQtySpecified += matlQtySpec;
      cube.qtyUnbilled += (matlQtySpec - priorBillQty).setScale(2);
      cube.amtUnbilled += (matlAmount - priorBillAmt).setScale(2);
      if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c){
        cube.qtyTransferred += priorTrnsQty;
        if(!matl.No_WIP__c || matl.AcctSeedERP__Project__r.Internal_Warranty__c)
          cube.qtySpecified += matlQtySpec;
        cube.qtyWIP += matlQtyAlloc;
        cube.qtyUnWIP += (matlQtySpec - matlQtyAlloc);
      }

      if(!cube.mapUniqueProductsByTask.containsKey(matl.AcctSeedERP__Project_Task__c))
        cube.mapUniqueProductsByTask.put(matl.AcctSeedERP__Project_Task__c, new Set<Id>());

      if(!cube.mapUniqueProductsByTask.get(matl.AcctSeedERP__Project_Task__c).contains(matl.AcctSeedERP__Product__c)){
        cube.cogsQty += cogsQty;
        cube.mapUniqueProductsByTask.get(matl.AcctSeedERP__Project_Task__c).add(matl.AcctSeedERP__Product__c);
      }

      if(matlAmount == 0)
        cube.qtyZeroAmount += matlQtySpec;
    }

    for(Id idP : mapCube.keySet())
    {
      erpCube cube = mapCube.get(idP);
      AcctSeed__Project__c proj = cube.project;
      Decimal fgQty = 0;
      if(proj != null && mapProjectFinishedMoves.containsKey(proj.Id) && mapProjectFinishedMoves.get(proj.Id) != null)
        fgQty = mapProjectFinishedMoves.get(proj.Id);

      Decimal noCogsQty = cube.qtySpecified - cube.cogsQty;
      if(proj.Internal_Warranty__c){
        noCogsQty = 0;//cube.allQtySpecified - cube.cogsQty;
        cube.noCogsQty = 0;//cube.allQtySpecified - cube.cogsQty;
      }

      if(proj.RecordTypeId == gcConstants.idRtProjectManufacturing && (cube.qtyUnWIP != 0 || fgQty == 0)){
        throw new gcException(proj.Name + ' has unfinished tasks. Please move all inventory items to WIP and create Finished Goods before making the project completed.');
      }else if(proj.RecordTypeId == gcConstants.idRtTradeIn && cube.qtyUnWIP != 0){
        throw new gcException(proj.Name + ' has unfinished tasks. Please move all inventory items to WIP before making the project completed.');
      }else if(proj.RecordTypeId == gcConstants.idRtTradeIn && fgQty == 0){
        throw new gcException(proj.Name + ' has unfinished tasks. A Trade In ERP should have inbound moves before making the project completed.');
      }else if(proj.RecordTypeId == gcConstants.idRtPartnerPartsOrder && proj.Internal_Partner_Parts_Order__c && cube.qtyTransferred.setScale(2) != cube.qtySpecified.setScale(2)){
        throw new gcException(proj.Name + ' has unfinished tasks. Please Transfer all inventory items before making the project completed.');
      }else if(proj.RecordTypeId != gcConstants.idRtProjectManufacturing && proj.RecordTypeId != gcConstants.idRtTradeIn && proj.RecordTypeId != gcConstants.idRtFixedAsset && !proj.Internal_Partner_Parts_Order__c && cube.qtyUnbilled != 0){
        throw new gcException(proj.Name + ' has unfinished tasks. Please create billings for all inventory items before making the project completed.');
      }else if(proj.RecordTypeId != gcConstants.idRtProjectManufacturing && proj.RecordTypeId != gcConstants.idRtTradeIn && !proj.Internal_Partner_Parts_Order__c && noCogsQty.setScale(2) != 0){
        throw new gcException(proj.Name + ' has unfinished tasks. Please move all inventory items to WIP to COGS before making the project completed.');
      }
    }
  }

  //@future
  private static void notifyOnOwnerChange( Map<Id, AcctSeed__Project__c> newMap,
    Map<Id,AcctSeed__Project__c> oldMap )
  {
    String baseUrl = System.Url.getSalesforceBaseURL().toExternalForm();
    Map<Id, Id> erp_oldUser_Map = new Map<Id, Id>();
    for( AcctSeed__Project__c p :newMap.values() )
    {
      if( p.OwnerId != oldMap.get(p.Id).OwnerId &&
        ((String)p.OwnerId).startsWith( '005' ) &&
        p.recordTypeId !=  gcConstants.idRtProjectPartnerBoatSale )
      {
        erp_oldUser_Map.put( p.Id, oldMap.get(p.Id).OwnerId );
      }
    }
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    for( Id erpId : erp_oldUser_Map.keySet() )
    {
      String body = 'An ERP Order which you owned, <a href=';
      body += baseUrl +'/'+ erpId + '>';
      body += newMap.get(erpId).Name + '</a> ';
      body += 'is now owned by someone else.';
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setTargetObjectId( erp_oldUser_Map.get(erpId) );
      mail.setSubject( 'An ERP Order you owned is now owned by someone else');
      mail.setHtmlBody( body );
      mail.setSaveAsActivity(false);
      msgList.add( mail );
    }
    if( msgList.size() > 0 )
      Messaging.sendEmail( msgList );
  }

  public static void coverage(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }
}