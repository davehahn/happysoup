public with sharing class lgnd_QuickPartsCreateController {
  public class Product_PartCreate_Exception Extends Exception{}

  public class DataWrapper {
    public Product2 part { get; set; }
    public String externalReferenceId { get; set; }
    public Decimal retailPrice { get; set; }
    public Decimal partnerPrice { get; set; }

    public DataWrapper(){}

    public DataWrapper( String externalProductId )
    {
      String sObjectType = LGND_Utilities.sObjectNameFromId( externalProductId );
      if( sObjectType == 'Mercury_Product__c' )
        this.newFromMercuryProduct( externalProductId );
      else
        throw new Product_PartCreate_Exception('Invalid External Product Id Supplied');
    }

    private void newFromMercuryProduct( Id recId )
    {
      Mercury_Product__c mp = [SELECT Id,
                                      Description__c,
                                      Code__c,
                                      UPC__c,
                                      MSRP__c,
                                      List_Price__c,
                                      Salesforce_Product__c
                               FROM Mercury_Product__c
                               WHERE Id = :recId ];
      if( mp.Salesforce_Product__c != null )
        throw new Product_PartCreate_Exception( 'Mercury Product already linked to a Salesforce Product');
      this.externalReferenceId = recId;
      this.retailPrice = mp.MSRP__c;
      this.part = new Product2(
        Name = mp.Description__c,
        Unique_Product_Code__c = mp.Code__c,
        Bar_Code__c = mp.UPC__c,
        AcctSeed__Unit_Cost__c = mp.List_Price__c,
        Taxable__c = true,
        AcctSeed__Inventory_Product__c = true,
        AcctSeedERP__Default_Vendor__c = Utility_Account__c.getOrgDefaults().Mercury__c,
        Description = '',
        Description_FR__c = ''
      );
    }

    public void linkProduct( Id prodId )
    {
      if( this.externalReferenceId != null )
      {
        String sObjectType = LGND_Utilities.sObjectNameFromId( this.externalReferenceId );
        if( sObjectType == 'Mercury_Product__c' )
          linkMercuryProduct( prodId );
      }
    }

    private void linkMercuryProduct( Id prodId )
    {
      Mercury_Product__c mp = new Mercury_Product__c(
        Id = this.externalReferenceId,
        Salesforce_Product__c = prodId
      );
      update mp;
    }
  }

  public class OptionsWrapper {
    public Account[] suppliers { get; set; }
    public String[] unitsOfMeasure { get; set; }
    public String[] familyOptions { get; set; }
    public DataWrapper dataWrapper { get; set; }
    public OptionsWrapper(){
      setFamilyOptions();
    }
    public OptionsWrapper( String externalProductId )
    {
      this.familyOptions = new List<String>();
      if( externalProductId != null || externalProductId.length() > 0 )
      {
        this.dataWrapper = new DataWrapper( externalProductId );
        this.familyOptions = LGND_Utilities.getPicklistValues('Product2', 'Family');
      }
    }

    private void setFamilyOptions(){
      this.familyOptions = new List<String>();
      for( Family_by_Record_Type__mdt f : Family_by_Record_Type__mdt.getAll().values() ){
        if( f.Family_by_Record_Type__c == 'Part' ){
          this.familyOptions.add(f.Label);
        }
      }
      this.familyOptions.sort();
    }

  }

  @AuraEnabled
  public static String fetchInitOptions( String externalProductId )
  {
    Id supplierRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Supplier');
    OptionsWrapper result;
    if( externalProductId == null )
      result = new OptionsWrapper();
    else
    {
      try {
        result = new OptionsWrapper( externalProductId );
      }
      catch( Exception e )
      {
        AuraHandledException err = new AuraHandledException( e.getMessage() );
        err.setMessage( e.getMessage() );
        throw err;
      }
    }

    result.suppliers =  [ SELECT Id, Name
                          FROM Account
                          WHERE RecordTypeId = :supplierRtId
                          AND Active__c = true
                          ORDER BY Name ASC ];
    result.unitsOfMeasure = LGND_Utilities.getPicklistValues('Product2', 'Unit_of_Measurement__c');
    return JSON.serialize(result);
  }


  @AuraEnabled
  public static Product2 createPart( String jsonData )
  {
    Id partRtId = LGND_Utilities.recordTypeIdFromName('Product2', 'Part');
    DataWrapper wrapper = (DataWrapper)JSON.deserialize( jsonData, DataWrapper.class);
    Product2 part = wrapper.part;
    part.RecordTypeId = partRtId;
    part.isActive = true;
    if( part.Name_FR__c == null || part.Name_FR__c == '' )
      part.Name_FR__c = part.Name;
    if( part.Description_FR__c == null || part.Description_FR__c == '' )
      part.Description_FR__c = part.Description;

    System.debug( part );
    insert part;
    wrapper.linkProduct( part.Id );
    System.debug( part );
    insert createPricebookEntry( part.Id, 'standard', wrapper.retailPrice );
    PricebookEntry[] pbes = new List<PricebookEntry>();
    if( wrapper.retailPrice != null )
      pbes.add( createPricebookEntry( part.Id, 'retail', wrapper.retailPrice ) );
    if( wrapper.partnerPrice != null )
      pbes.add( createPricebookEntry( part.Id, 'partner', wrapper.partnerPrice ) );
    insert pbes;
    return part;
  }

  private static PricebookEntry createPricebookEntry( Id partId, String pbType, Decimal price )
  {
    Id pbId;
    if( pbType == 'standard' )
      pbId = LGND_Constants.standardPricebookId;
    if( pbType == 'retail' )
      pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    if( pbType == 'partner' )
      pbId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;

    return new PricebookEntry(
      Pricebook2Id = pbId,
      Product2Id = partId,
      isActive = true,
      UnitPrice = price,
      UseStandardPrice = false
    );
  }

}