public with sharing class Mercury_Product_dh {

  public static Boolean disableTrigger {
    get {
      if( disableTrigger == null )
      {
        disableTrigger = false;
      }
      return disableTrigger;
    }
    set;
  }

  public static void triggerHandler( Map < Id, Mercury_Product__c > oldMap,
                                     Map < Id, Mercury_Product__c > newMap,
                                     List < Mercury_Product__c > listNew,
                                     Boolean boolIsBefore,
                                     Boolean boolIsInsert,
                                     Boolean boolIsUpdate,
                                     Boolean boolIsDelete )
  {
    System.debug( 'RUNNING MERCURY PRODUCT TRIGGER' );
    if (oldMap == null) oldMap = new Map < Id, Mercury_Product__c > ();
    if (newMap == null) newMap = new Map < Id, Mercury_Product__c > ();
    if (listNew == null) listNew = new List < Mercury_Product__c > ();

    if (boolIsBefore)
    /* &&&&&&&   BEFORE    &&&&&&& */
    {
      System.debug( 'RUNNING BEFORE' );
      if (boolIsInsert) {
        fixItemClassLength( listNew );
        checkIfExistsInSalesforce( listNew );
      }
      if (boolIsUpdate) {
        fixItemClassLength( listNew );
        checkIfExistsInSalesforce( listNew );
      }
      if (boolIsDelete) {
      }
    } else {
      /* &&&&&&&   AFTER   &&&&&&& */
      System.debug( 'RUNNING AFTER' );
      if (boolIsInsert) {
        updatePricebookEntries( onlySalesforceProducts( listNew ) );
      }
      if (boolIsUpdate) {
        updatePricebookEntries( onlySalesforceProducts( listNew ) );
      }
      if (boolIsDelete) {
      }
    }
  }

  /* ++++++++++++ PRIVATES +++++++++++ */

  private static void fixItemClassLength( Mercury_Product__c[] listNew )
  {
    for( Mercury_Product__c mp : listNew )
    {
      if( mp.Item_Class__c != null )
        mp.Item_Class__c = mp.Item_Class__c.leftPad( 4, '0' );
    }
  }

  private static void checkIfExistsInSalesforce( Mercury_Product__c[] listNew )
  {
    Id mercAccount = Utility_Account__c.getOrgDefaults().Mercury__c;
    Map<String, Mercury_Product__c> codeMap = new Map<String, Mercury_Product__c>();
    for( Mercury_Product__c mp : listNew )
    {
      if( mp.Code__c != null && mp.Salesforce_Product__c == null)
        codeMap.put( mp.Code__c, mp );
    }
    for( Product2 p : [SELECT Id, ProductCode
                       FROM Product2
                       WHERE ProductCode IN : codeMap.keySet()
                       AND AcctSeedERP__Default_Vendor__c = :mercAccount ] )
    {
      if( codeMap.containsKey( p.ProductCode ) )
        codeMap.get(p.ProductCode).Salesforce_Product__c = p.Id;
    }
  }

  private static Mercury_Product__c[] onlySalesforceProducts( Mercury_Product__c[] listNew )
  {
    Mercury_Product__c[] result = new List<Mercury_Product__c>();
    for( Mercury_Product__c mp : listNew )
    {
      if( mp.Salesforce_Product__c != null )
        result.add( mp );
    }
    return result;
  }

  private static void updatePricebookEntries( Mercury_Product__c[] listNewSF_only )
  {
    PriceBookUpdate pbu = new PriceBookUpdate( listNewSF_only );
    System.enqueueJob( pbu );
  }

  public class PriceBookUpdate implements Queueable
  {
    private Mercury_Product__c[] mProds;

    public PriceBookUpdate( Mercury_Product__c[] listNewSF_only )
    {
      this.mProds = listNewSF_only;
    }

    public void execute( QueueableContext cont )
    {
      Map<String, Id> pbMap = new Map<String, Id>{
        'retail' => LGND_Constants.retailPricebookId,
        'factory' => LGND_Constants.factoryPricebookId,
        'standard' => LGND_Constants.standardPricebookId
      };
      Id mercAccount = Utility_Account__c.getOrgDefaults().Mercury__c;
      Map<Id, Mercury_Product__c> prodId_mProd_map = new Map<Id, Mercury_Product__c>();
      for( Mercury_Product__c mp : mProds )
      {
        prodId_mProd_map.put( mp.Salesforce_Product__c, mp );
      }

      Product2[] prods = [SELECT Id, ( SELECT Id, Pricebook2Id, Product2Id
                                       FROM PricebookEntries
                                       WHERE Pricebook2Id IN : pbMap.values() )
                          FROM Product2
                          WHERE Id IN :prodId_mProd_map.keySet()
                          AND AcctSeedERP__Default_Vendor__c = :mercAccount];
      PricebookEntry[] stdPbes = new List<PricebookEntry>();
      PricebookEntry[] pbes = new List<PricebookEntry>();
      for( Product2 p : prods )
      {
        //update Unit cost of the product
        p.AcctSeed__Unit_Cost__c = prodId_mProd_map.get(p.Id).List_Price__c;
        Boolean hasRetail = false;
        Boolean hasStandard = false;
        Boolean hasFactory = false;
        for( PricebookEntry pbe : p.PricebookEntries )
        {
          if( pbe.Pricebook2Id == pbMap.get('standard') )
          {
            hasStandard = true;
          }
          if( pbe.Pricebook2Id == pbMap.get('retail') )
          {
            hasRetail = true;
            pbe.UnitPrice = prodId_mProd_map.get(pbe.Product2Id).MSRP__c;
            pbe.UseStandardPrice = false;
            pbes.add( pbe );
          }
          if( pbe.Pricebook2Id == pbMap.get('factory') )
          {
            hasFactory = true;
            pbe.UnitPrice = prodId_mProd_map.get(pbe.Product2Id).List_Price__c;
            pbe.UseStandardPrice = false;
            pbes.add( pbe );
          }
        }
        if( !hasStandard )
          stdPbes.add( createPbEntry( p.Id, pbMap.get('standard'), 0.00 ) );
        if( !hasRetail )
          pbes.add( createPbEntry( p.Id, pbMap.get('retail'), prodId_mProd_map.get(p.Id).MSRP__c ) );
        if( !hasFactory )
          pbes.add( createPbEntry( p.Id, pbMap.get('factory'), prodId_mProd_map.get(p.Id).List_Price__c ) );
      }
      if( stdPbes.size() > 0 )
        insert stdPbes;

      upsert pbes;
      Boolean ot = gcProduct.disableTrigger;
      gcProduct.disableTrigger = true;
      update prods;
      gcProduct.disableTrigger = ot;
    }

    private PricebookEntry createPbEntry( Id prodId, Id pbId, Decimal price )
    {
      return new PricebookEntry(
        UseStandardPrice = false,
        Product2Id = prodId,
        Pricebook2Id = pbId,
        UnitPrice = price,
        IsActive = true
      );
    }

  }


}