/**
 * Created by dave on 2021-07-06.
 */

@IsTest
public class Factory_OperatingHours
{


  public static OperatingHours insertBase()
  {
    OperatingHours record = new OperatingHours(
      Name = 'Base Calendar',
      TimeZone = 'America/New_York'
    );
    insert record;
    return record;
  }

}