/**
 * Created by dave on 2023-01-27.
 */

public with sharing class CPQ_WarrantyService_Controller {

  @AuraEnabled(Cacheable=true)
  public static String initServiceAndWarranty(String recordId, String pbId) {
    return BusinessOffice_Controller.initServiceAndWarranty(recordId, pbId);
  }

  @AuraEnabled
  public static String fetchSubOptions(String parentProductId, String pricebookId){
    return CPQ_Controller_dh.fetchSubOptions1( parentProductId, pricebookId);
  }

}