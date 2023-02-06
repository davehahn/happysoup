/**
 * Created by dave on 2023-01-27.
 */

public with sharing class CPQ_WarrantyService_Controller {
  @AuraEnabled(Cacheable=true)
  public static String initServiceAndWarranty(String recordId, String pbId) {
    return BusinessOffice_Controller.initServiceAndWarranty(recordId, pbId);
  }

  @AuraEnabled
  public static String fetchSubOptions(String parentProductId, String pricebookId) {
    return CPQ_Controller_dh.fetchSubOptions1(parentProductId, pricebookId);
  }

  @AuraEnabled(Cacheable=true)
  public static String findWarAndServiceOptions(List<String> selectedProductIds, String pricebookId) {
    System.debug(selectedProductIds);
    WarrantyAndServiceItemsWrapper result = new WarrantyAndServiceItemsWrapper();
    Product_Option__c[] options = [
      SELECT Id, From_Product__c, Standard__c, Maximum__c, To_Product__r.Id, To_Product__r.Name
      FROM Product_Option__c
      WHERE
        To_Product__c IN :selectedProductIds
        AND (From_Product__r.Family = 'Extended Warranty'
        OR From_Product__r.RecordType.Name = 'Protection and Services'
        OR From_Product__r.RecordType.Name = 'Package Bundle')
    ];
    if (!options.isEmpty()) {
      Map<Id, Product_Option__c> availOptionsMap = new Map<Id, Product_Option__c>();
      for (Product_Option__c po : options) {
        availOptionsMap.put(po.From_Product__c, po);
      }

      List<Product2> prods = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          RecordType.Name,
          Family,
          Make__c,
          Standard_Motor__c,
          Standard_Trailer__c,
          Standard_Trolling_Motor__c,
          Default_Image_Thumb__c,
          isPrepayable__c,
          Taxable__c,
        (
          SELECT Id, UnitPrice, Pricebook2Id, IsActive
          FROM PricebookEntries
          WHERE Pricebook2Id = :pricebookId
        )
        FROM Product2
        WHERE Id IN :availOptionsMap.keySet()
      ];

      for( Product2 p : prods ){
        Product_Option__c opt = availOptionsMap.get(p.Id);
        if (p.Family == 'Extended Warranty')
        {
          result.warranty.add(new CPQ_Lib_dh.WarrantyOptionProduct(p, opt.To_Product__r, opt.Standard__c, opt.Maximum__c));
          continue;
        }
        if (
          p.RecordType.Name == 'Protection and Services' ||
          p.RecordType.Name == 'Package Bundle'
        ) {
          System.debug(opt);
          result.service.add( new CPQ_Lib_dh.MaintenanceServicePlanOptionProduct(p, opt.To_Product__r, opt.Standard__c, opt.Maximum__c));
          continue;
        }
      }
    }

    return JSON.serialize(result);
  }

  public class WarrantyAndServiceItemsWrapper {
    public CPQ_Lib_dh.WarrantyOptionProduct[] warranty { get; set; }
    public CPQ_Lib_dh.MaintenanceServicePlanOptionProduct[] service { get; set; }
    //public Set<Id> selectedLineIds { get; set; }

    public WarrantyAndServiceItemsWrapper() {
      this.warranty = new List<CPQ_Lib_dh.WarrantyOptionProduct>();
      this.service = new List<CPQ_Lib_dh.MaintenanceServicePlanOptionProduct>();
      //this.selectedLineIds = new Set<Id>();
    }
  }
}
