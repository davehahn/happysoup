/**
 * Created by dave on 2020-02-28.
 */

public class UtilityComponent_Controller
{

  @AuraEnabled
  public static List<Map<String, String>> doLiveLookup(
    String sObjectName,
    String query,
    List<String> returnFields,
    List<String> filterFields,
    String whereClause )
  {
    LiveLookupInput lookUp = new LiveLookupInput(
      sObjectName,
      returnFields,
      filterFields,
      query,
      whereClause);
    return lookUp.run();
  }


  public class LiveLookupInput
  {

    public List<String> fields;
    public String sObjectName;
    public List<String> filterFields;
    public String filterString;
    public String whereClause;
    private String queryString;

    public LiveLookupInput( String sObjectName,
                            List<String> fields,
                            List<String> filterFields,
                            String query,
                            String whereClause )
    {
      this.sObjectName = sObjectName;
      this.fields = fields;
      if( !fields.contains('Id') )
      {
        fields.add(0, 'Id');
      }
      this.queryString = 'SELECT ';
      this.filterFields = filterFields;
      this.filterString = String.escapeSingleQuotes( query );
      this.whereClause = whereClause;
    }

    public List<Map<String, String>> run()
    {
      buildQueryString();
      List<Map<String, String>> result = new List<Map<String, String>>();
      for( sObject obj : Database.query( this.queryString ) )
      {
        Map<String, String> r = new Map<String, String>();
        for( String field : this.fields )
        {
          r.put( field, String.valueOf(obj.get(field) ) );
        }
        result.add( r );
      }
      return result;
    }

    private void buildQueryString()
    {
      for( String field : this.fields )
      {
        this.queryString += field + ',';
      }
      this.queryString = this.queryString.removeEnd(',');
      this.queryString += ' FROM ' + this.sObjectName + ' WHERE ';
      for( String field : this.filterFields )
      {
        this.queryString += field + ' LIKE \'%' + this.filterString + '%\' AND ';
      }
      if( this.whereClause != null && this.whereClause.length() > 0 )
      {
        this.queryString += this.whereClause;
      }
      else
      {
        this.queryString = this.queryString.removeEnd(' AND ');
      }
      System.debug( this.queryString );
    }
  }

}