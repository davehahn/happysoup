/**
 * Created by dave on 2019-11-15.
 */
@IsTest
public class Factory_CasePart
{

  public static List<Case_Part__c> create( Case theCase, Integer count )
  {
    List<Case_Part__c> result = new List<Case_Part__c>();
    for( Product2 p : Factory_Product.createNonSerializedProducts('Part', 'Electronics', count) )
    {
      result.add( new Case_Part__c(
        Case__c = theCase.Id,
        Product__c = p.Id,
        Order_Quantity__c = 1,
        Unit_Price__c = 10
      ) );
    }
    insert result;
    return result;
  }

}