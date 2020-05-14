/**
 * Created by dave on 2020-05-13.
 */

public with sharing class Lead_Selector extends Application_Selector
{

  public Lead_Selector()
  {
    this.sObjectName = 'Lead';
    this.fields = new List<String>{
      'Id',
      'FirstName',
      'LastName',
      'Email',
      'Company',
      'IsConverted'
    };
  }

  public static List<Lead> allNonConvertedByEmail( String email )
  {
    Lead_Selector selector = new Lead_Selector();
    selector
      .addWhere('IsConverted = false')
      .addWhere( 'Email = \'' + email +'\'', 'AND' );
    return (List<Lead>)selector.query();
  }
}