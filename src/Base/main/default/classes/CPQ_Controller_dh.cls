public with sharing class CPQ_Controller_dh {
  /* recordId - the record we want to use to populate the CPQ entries against
                usually a quoteId for when we are editing a quote, but could be
                an OppId as well
     opportunityId - the opportunityId if we are creating a new quote. We need
                     this to get the Tax Excemption status of the Account
  */
  @AuraEnabled
  public static String initCPQ(String recordId, String opportunityId) {
    try {
      //if( recordId == null )
      //{
      //  return JSON.serialize( new CPQ('retail') );
      //}
      return JSON.serialize(new CPQ('retail', recordId, opportunityId));
    } catch (Exception e) {
      AuraHandledException aex = new AuraHandledException(e.getMessage());
      aex.setMessage(e.getMessage());
      throw aex;
    }
  }

  @AuraEnabled
  public static String fetchTaxZones() {
    List<CPQ_Lib_dh.TaxZone> result = new List<CPQ_Lib_dh.TaxZone>();
    for (AcctSeed__Accounting_Variable__c aVar : [
      SELECT Id, Name, Tax_is_Harmonized__c, Tax_Rate_Provincial_Statutory__c, Tax_Rate_Retail__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3'
    ]) {
      result.add(new CPQ_Lib_dh.TaxZone(aVar));
    }
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String upsertQuote(String recordId, String name, String expireDate, String taxZoneJSON) {
    CPQ_Lib_dh.TaxZone taxZone = (CPQ_Lib_dh.TaxZone) JSON.deserialize(taxZoneJSON, CPQ_Lib_dh.TaxZone.class);
    String sObjectType = LGND_Utilities.sObjectNameFromId(recordId);
    Boolean doSync = false;
    Opportunity opp;
    Quote q = new Quote(
      Name = name,
      ExpirationDate = expireDate == null ? null : Date.valueOf(expireDate),
      GL_Account_Variable_3__c = taxZone.id,
      Tax_Rate_Federal__c = taxZone.federalRate,
      Tax_Rate_Provincial__c = taxZone.provincialRate,
      TradeInLien__c = 0,
      TradeInAmount__c = 0
    );
    switch on sObjectType {
      when 'Quote' {
        q.Id = recordId;
      }
      when 'Opportunity' {
        opp = [SELECT Id, Pricebook2Id, SyncedQuoteId, (SELECT Id FROM Quotes) FROM Opportunity WHERE Id = :recordId];
        q.OpportunityId = opp.Id;
        q.Pricebook2Id = opp.Pricebook2Id;
        if (opp.SyncedQuoteId == null && opp.Quotes.isEmpty()) {
          doSync = true;
        }
      }
      when else {
        AuraHandledException aex = new AuraHandledException('Unsupported record Id provided');
        aex.setMessage('Unsupported record Id provided');
        throw aex;
      }
    }
    upsert q;
    if (opp != null && doSync) {
      opp.SyncedQuoteId = q.Id;
      update opp;
    }
    return q.Id;
  }

  @AuraEnabled
  public static String saveCPQ(String cpqJSON) {
    CPQ theCPQ = (CPQ) JSON.deserialize(cpqJSON, CPQ.class);
    System.debug('saveToRecordId = ' + theCPQ.saveToRecordId);
    try {
      return theCPQ.save();
    } catch (Exception e) {
      AuraHandledException aex = new AuraHandledException(e.getMessage());
      aex.setMessage(e.getMessage());
      throw aex;
    }
  }

  //  @AuraEnabled
  //  public static String fetchMajorProductOptions( String recordType,
  //                                                 String family,
  //                                                 String activePricebookId )
  //  {
  //    return JSON.serialize( CPQ.fetchMajorProductSelectOptions( recordType, family, activePricebookId ) );
  //  }

  @AuraEnabled
  public static String fetchMajorProductOptions(
    String recordType,
    String family,
    String activePricebookId,
    Boolean allowInactiveEntries
  ) {
    return JSON.serialize(
      CPQ.fetchMajorProductSelectOptions(recordType, family, activePricebookId, allowInactiveEntries)
    );
  }

  @AuraEnabled
  public static String fetchBoatDetails(String cpqJSON) {
    CPQ theCPQ = (CPQ) JSON.deserialize(cpqJSON, CPQ.class);
    try {
      theCPQ.selectBoat();
      return JSON.serialize(theCPQ);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /* +++++++++++ SAVINGS +++++++++++++++ */

  @AuraEnabled
  public static String fetchNewSavings() {
    return JSON.serialize(new CPQ_Lib_dh.SavingsLine());
  }

  /* +++++++++++ ADDITIONAL ACCESSORY ++++++++++ */
//  @AuraEnabled
//  public static String fetchAdditionalAccessory( Id prodId ){
//    return JSON.serialize( new CPQ_Lib_dh.AdditionalAccessory( prodId ) );
//  }


  /* +++++++++++ PARTNER CUSTOM PRODUCT ++++++++ */
  @AuraEnabled
  public static String fetchNewCustomProduct() {
    return JSON.serialize(new CPQ_Lib_dh.CustomProduct());
  }

  /*  +++++++++++++++++++++++ UPGRADE SELECTOR +++++++++++++++++++++++ */
  /*
    initialize the upgrade selector component
    @params {
      String parentProductId - the Id of the Boat Product,
      String upgradeType - Product RecordType of the upgrade Motor/Trailer/Trolling Motor
    }

  */
  @AuraEnabled
  public static String initUpgradeSelector(String cpqJSON, String upgradeType) {
    CPQ theCPQ = (CPQ) JSON.deserialize(cpqJSON, CPQ.class);
    //try {
    return JSON.serialize(theCPQ.buildUpgrades(upgradeType));
    //}
    //catch(Exception e)
    //{
    //  throw new AuraHandledException( e.getMessage() );
    //}
  }

  @AuraEnabled
  public static String setSelectedUpgrade(String fromId, String toId, String activePricebookId, String province) {
    return JSON.serialize(CPQ.setUpgrade(fromId, toId, activePricebookId, province));
  }

  @AuraEnabled
  public static String fetchOptions(String parentProductId, String activePricebookId) {
    return JSON.serialize(CPQ.groupOptions(CPQ.fetchAllOptions(parentProductId, activePricebookId)));
  }

  @AuraEnabled
  public static String fetchSubOptions1(String parentProductId, String activePricebookId) {
    Map<Id, Product_Option__c> optionMap = new Map<Id, Product_Option__c>();
    List<CPQ_Lib_dh.SubOptionProduct> result = new List<CPQ_Lib_dh.SubOptionProduct>();
    Id partId = LGND_Constants.productRtId_Part;
    for (Product_Option__c po : [
      SELECT Id, From_Product__c, Standard__c, Maximum__c
      FROM Product_Option__c
      WHERE To_Product__c = :parentProductId AND From_Product__r.RecordTypeId = :partId
    ]) {
      /*
        don't allow selected and not selectable options ( standard == maximum)
        if this is for a partner
        ***** CURRENTLY ONLY IN SAMPLE RETAIL CALCULATOR ********
      */
      System.debug('***** Product Option - ' + po);
      if (!(CPQ_Lib_dh.defaultPricebooks.get('partner') == activePricebookId && po.Standard__c == po.Maximum__c)) {
        optionMap.put(po.From_Product__c, po);
      }
    }
    for (Product2 p : [
      SELECT
        Id,
        Name,
        RecordType.Name,
        Family,
        Make__c,
        Standard_Motor__c,
        Standard_Trailer__c,
        Standard_Trolling_Motor__c,
        Default_Image_Thumb__c,
        Taxable__c,
        (
          SELECT Id, UnitPrice, Pricebook2Id, IsActive
          FROM PricebookEntries
          WHERE Pricebook2Id IN :CPQ_Lib_dh.defaultPricebooks.values()
        )
      FROM Product2
      WHERE Id IN :optionMap.keySet()
    ]) {
      String fam = String.isEmpty(p.Family) ? 'Misc' : p.Family;
      CPQ_Lib_dh.SubOptionProduct op = new CPQ_Lib_dh.SubOptionProduct(
        p,
        parentProductId,
        optionMap.get(p.Id).Standard__c,
        optionMap.get(p.Id).Maximum__c
      );
      /*
        If this for a partner and there is no partner price ( not in partner PB )
        then we do not want it
      */
      if ((CPQ_Lib_dh.defaultPricebooks.get('partner') == activePricebookId && op.partnerPrice != null)) {
        result.add(op);
      }
      if (
        CPQ_Lib_dh.defaultPricebooks.get('retail') == activePricebookId &&
        op.retailPrice != null &&
        op.retailPricebookEntryIsActive
      ) {
        result.add(op);
      }
    }
    return JSON.serialize(result);
  }

  // Older function part of BusinessOffice_FI comonent
  @AuraEnabled
  public static String fetchSubOptions(String parentProductId, String pricebookId) {
    List<CPQ_Lib_dh.OptionWrapper> result = new List<CPQ_Lib_dh.OptionWrapper>();
    Map<Id, Product_Option__c> optionMap = new Map<Id, Product_Option__c>();
    //Set<Id> productIds = new Set<Id>();
    for (Product_Option__c option : [
      SELECT From_Product__c, Standard__c, Maximum__c
      FROM Product_Option__c
      WHERE To_Product__c = :parentProductId
    ]) {
      //productIds.add( option.From_Product__c );
      optionMap.put(option.From_Product__c, option);
    }
    for (PricebookEntry pbe : [
      SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.isPrepayable__c
      FROM PricebookEntry
      WHERE Product2Id IN :optionMap.keySet() AND Pricebook2Id = :pricebookId
    ]) {
      Product_Option__c op = optionMap.get(pbe.Product2Id);
      CPQ_Lib_dh.OptionWrapper ow = new CPQ_Lib_dh.OptionWrapper(pbe, op.Standard__c, op.Maximum__c);
      ow.parentProductId = parentProductId;
      result.add(ow);
    }
    return JSON.serialize(result);
  }
}
