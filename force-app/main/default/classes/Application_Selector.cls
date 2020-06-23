/**
 * Created by dave on 2020-03-24.
 */

public virtual class Application_Selector
{
  protected String sObjectName;
  protected List<String> fields;
  private List<String> whereClause;
  private String orderBy;
  protected List<String> childQueries;

  public Application_Selector()
  {
  }

  public Application_Selector addWhere( String whereClause )
  {
    if( whereClause == null || whereClause.length() == 0 )
      return this;
    if( this.whereClause == null || this.whereClause.size() == 0 )
    {
      this.whereClause = new List<String>{'WHERE ' + whereClause };
      return this;
    }
    this.whereClause.add( 'AND ' + whereClause );
    return this;
  }

  public Application_Selector addWhereIdIn( Set<Id> ids )
  {
    Set<String> s_ids = (Set<String>)JSON.deserialize( JSON.serialize( ids ), Set<String>.class );
    addWhere( whereInClauseBuilder('Id', s_ids ) );
    return this;
  }

  public Application_Selector addWhereIdInField( Set<Id> ids, String idField )
  {
    Set<String> s_ids = (Set<String>)JSON.deserialize( JSON.serialize( ids ), Set<String>.class );
    addWhere( whereInClauseBuilder(idField, s_ids ) );
    return this;
  }

  public Application_Selector addOrderBy( String orderBy )
  {
    this.orderBy = orderBy;
    return this;
  }

  public Application_Selector addFields( List<String> fields )
  {
    this.fields.addAll( fields );
    return this;
  }

  public Application_Selector addChildQuery( String q )
  {
    if( this.childQueries == null )
      this.childQueries = new List<String>();
    this.childQueries.add( q );
    return this;
  }

  public List<SObject> query()
  {
    try
    {
      return Database.query(this.buildQueryString());
    }
    catch( Exception e )
    {
      System.debug( e.getMessage() );
      return new List<SObject>();
    }
  }

  private String buildQueryString()
  {
    String queryString = 'SELECT ';
    for( String field : this.fields )
    {
      queryString += field + ',';
    }
    if( this.childQueries != null && this.childQueries.size() > 0 )
    {
      for( String child : this.childQueries )
      {
        queryString += child + ',';
      }
    }
    queryString = queryString.removeEnd(',');
    queryString += ' FROM ' + this.sObjectName;
    for( String clause : this.whereClause )
    {
      System.debug( clause );
      queryString += ' ' + clause;
    }
    if( this.orderBy != null )
    {
      queryString += ' ORDER BY ' + this.orderBy;
    }
    System.debug( queryString );
    return queryString;
  }

  public static String whereInClauseBuilder( String field, Set<String> matchers )
  {
    if( matchers == null || matchers.size() == 0 )
      return null;

    if( matchers != null && matchers.size() == 1 )
      return field + ' = \'' + new List<String>(matchers)[0] + '\'';

    String w = field + ' IN (';
    for( Object m : matchers )
    {
      w += '\'' + m + '\',';
    }
    w = w.removeEnd(',') + ')';
    return w;
  }

  public static String toDateString( Date d )
  {
    return toDateString( DateTime.newInstance(
      d,
      Time.newInstance(0, 0, 0, 0)
    ));
  }

  public static String toDateString( DateTime dt )
  {
    return dt.format('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'');
  }

}