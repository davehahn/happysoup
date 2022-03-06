/**
 * Created by dave on 2020-12-09.
 */

public with sharing class ServiceResource_MyInventory_Controller
{

  @AuraEnabled(Cacheable=true)
  public static List<ProductItem> getMyInventory( Id serviceResourceId )
  {
    ServiceResource_Service srService = new ServiceResource_Service( serviceResourceId );
    return srService.getMyInventory();
  }
}