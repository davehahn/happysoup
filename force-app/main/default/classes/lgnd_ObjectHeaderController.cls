public with sharing class lgnd_ObjectHeaderController {


  @AuraEnabled
  public static String fetchRecordDetails( String sObjectName,
                                           String recordId,
                                           String[] fields )
  {
    String query = 'SELECT ';
    for( String f : fields )
    {
      query += f;
      query += ',';
    }
    query = query.removeEnd(',');
    query += ' FROM ';
    query += sObjectName;
    query += ' WHERE Id = \'' + recordId + '\'';
    System.debug( query );
    SObject result = Database.query( query );

    return JSON.serialize( result );
  }

  @AuraEnabled
  public static void deleteRecord( String recordId )
  {
    Database.delete( recordId );
  }
}