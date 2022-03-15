/**
 * Created by dave on 2021-07-05.
 */
@IsTest
public class Factory_ServiceTerritory
{

  public static ServiceTerritory insertWholeSale()
  {
    OperatingHours oh = Factory_OperatingHours.insertBase();
    ServiceTerritory st = new ServiceTerritory(
      Name = 'WholeSale',
      IsActive = true,
      OperatingHoursId = oh.Id
    );
    insert st;
    insert new FSL_Constants__c(
      Service_Territory_Wholesale__c = st.Id
    );
    return st;
  }

}