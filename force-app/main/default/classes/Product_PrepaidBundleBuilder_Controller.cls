public without sharing class Product_PrepaidBundleBuilder_Controller {

  public class BundleWrapper {
    public String id;
    public Prepaid_Package_Item__c[] selectedPackages;
    public Product2[] availablePackages;

    public BundleWrapper( String recordId )
    {
      this.id = recordId;
      this.selectedPackages = setSelectedPackages();
      this.availablePackages = setAvailablePackages();
    }

    private Prepaid_Package_Item__c[] setSelectedPackages()
    {
      if( this.id == null ) return new List<Prepaid_Package_Item__c>();
      return  [ SELECT Id,
                        Name,
                        Package__c,
                        Item__c,
                        Item__r.Name,
                        Quantity__c
                   FROM Prepaid_Package_Item__c
                  WHERE Package__c = :this.id ];
    }

    private Product2[] setAvailablePackages()
    {
      //if( this.selectedPackages.isEmpty() )
      //  return new List<Product2>();

      Set<Id> prodIds = new Set<Id>();
      for( Prepaid_Package_Item__c item : this.selectedPackages )
      {
        prodIds.add( item.Item__c );
      }
      return [ SELECT Id,
                      Name,
                      ProductCode
                 FROM Product2
                WHERE Family = 'Maintenance Package'
                  AND RecordType.Id = :LGND_Constants.productRtId_Protection
                  AND IsActive = true
                  AND Id NOT IN :prodIds];
    }
  }

  @AuraEnabled
  public static String initComponent( Id recordId )
  {
    return JSON.serialize( new BundleWrapper( recordId ) );
  }

  @AuraEnabled
  public static Prepaid_Package_Item__c addNewPackageToBundle( Prepaid_Package_Item__c newPackageItem )
  {
    insert newPackageItem;
    return [ SELECT Id,
                    Name,
                    Package__c,
                    Item__c,
                    Item__r.Name,
                    Quantity__c
               FROM Prepaid_Package_Item__c
              WHERE Id = :newPackageItem.Id ];
  }

  @AuraEnabled
  public static String removePackageFromBundle( String recordId, String packageId )
  {
    Prepaid_Package_Item__c pppi = new Prepaid_Package_Item__c(
      Id = packageId
    );
    delete pppi;
    return JSON.serialize( new BundleWrapper( recordId ) );
  }

  @AuraEnabled
  public static Prepaid_Package_Item__c[] updatePackages( String recordId,
                                                          Prepaid_Package_Item__c[] packages )
  {
    update packages;
    BundleWrapper bw = new BundleWrapper(recordId);
    return bw.selectedPackages;
  }
}