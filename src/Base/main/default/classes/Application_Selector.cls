/**
 * Created by dave on 2020-03-24.
 */

public virtual class Application_Selector {
  public class SelectorException extends Exception {
  }

  protected String sObjectName;
  protected List<String> fields;
  protected List<String> whereClause;
  private String orderBy;
  protected List<String> childQueries;

  public Application_Selector() {
  }

  public Application_Selector addWhere(String whereClause) {
    if (whereClause == null || whereClause.length() == 0)
      return this;
    if (this.whereClause == null || this.whereClause.size() == 0) {
      this.whereClause = new List<String>{ 'WHERE ' + whereClause };
      return this;
    }
    this.whereClause.add('AND ' + whereClause);
    return this;
  }

  public Application_Selector addWhere(String whereClause, String operator) {
    Set<String> acceptableOperators = new Set<String>{ 'AND', 'OR' };
    if (operator != null && !acceptableOperators.contains(operator))
      throwError(' An invalid operator was specified. Acceptable values are null, \'AND\' or \'OR\'');

    if (whereClause == null || whereClause.length() == 0)
      return this;
    if (this.whereClause == null || this.whereClause.size() == 0 || operator == null) {
      this.whereClause = new List<String>{ 'WHERE ' + whereClause };
      return this;
    }
    this.whereClause.add(operator + ' ' + whereClause);
    return this;
  }

  public Application_Selector addWhereIdIn(Set<Id> ids) {
    Set<String> s_ids = (Set<String>) JSON.deserialize(JSON.serialize(ids), Set<String>.class);
    return addWhere(whereInClauseBuilder('Id', s_ids));
  }

  public Application_Selector addWhereIdIn(List<Id> listIds) {
    return addWhereIdIn(new Set<Id>(listIds));
  }

  public Application_Selector addWhereIdInField(Set<Id> ids, String idField) {
    Set<String> s_ids = (Set<String>) JSON.deserialize(JSON.serialize(ids), Set<String>.class);
    addWhere(whereInClauseBuilder(idField, s_ids));
    return this;
  }
  public Application_Selector addWhereIdInField(Set<Id> ids, String idField, String operator) {
    Set<String> s_ids = (Set<String>) JSON.deserialize(JSON.serialize(ids), Set<String>.class);
    addWhere(whereInClauseBuilder(idField, s_ids), operator);
    return this;
  }

  public Application_Selector addWhereFieldNotIn(String fieldName, Set<String> ignoreStrings, String operator) {
    addWhere(whereNotInClauseBuilder(fieldName, ignoreStrings), operator);
    return this;
  }

  public Application_Selector addWhereFieldIn(String fieldName, Set<String> acceptableStrings, String operator) {
    addWhere(whereInClauseBuilder(fieldName, acceptableStrings), operator);
    return this;
  }

  public Application_Selector addOrderBy(String orderBy) {
    this.orderBy = orderBy;
    return this;
  }

  public Application_Selector addFields(List<String> fields) {
    this.fields.addAll(fields);
    return this;
  }

  public Application_Selector addChildQuery(String q) {
    if (this.childQueries == null)
      this.childQueries = new List<String>();
    this.childQueries.add(q);
    return this;
  }

  public Application_Selector addChildQuery(Application_Selector childSelector) {
    return addChildQuery(buildChildQuery(childSelector, null));
  }

  public Application_Selector addChildQuery(Application_Selector childSelector, String relationshipName) {
    return addChildQuery(buildChildQuery(childSelector, relationshipName));
  }

  public String buildChildQuery(Application_Selector childSelector, String relationshipName) {
    SObjectType sObjType = ((SObject) Type.forName(this.sObjectName).newInstance()).getSObjectType();
    String q = '(SELECT ';
    for (String f : childSelector.fields) {
      q += f + ', ';
    }
    q = q.removeEnd(', ');
    q += ' FROM ';
    if (relationshipName == null) {
      for (Schema.ChildRelationship cr : sObjType.getDescribe().getChildRelationships()) {
        if (cr.getChildSObject().getDescribe().getName() == childSelector.sObjectName) {
          relationshipName = cr.getRelationshipName();
          break;
        }
      }
    }
    q += relationshipName;
    if (childSelector.whereClause != null && childSelector.whereClause.size() > 0) {
      for (String clause : childSelector.whereClause) {
        q += ' ' + clause;
      }
    }
    q += ')';
    return q;
  }

  public List<SObject> query() {
    //    try
    //    {
    String qString = this.buildQueryString();
    return Database.query(qString);
    //    }
    //    catch( Exception e )
    //    {
    //      throwError( e.getMessage() );
    //      return null;
    //    }
  }

  public String buildQueryString() {
    String queryString = 'SELECT ';
    for (String field : this.fields) {
      queryString += field + ',';
    }
    if (this.childQueries != null && this.childQueries.size() > 0) {
      for (String child : this.childQueries) {
        queryString += child + ',';
      }
    }
    queryString = queryString.removeEnd(',');
    queryString += ' FROM ' + this.sObjectName;
    for (String clause : this.whereClause) {
      queryString += ' ' + clause;
    }
    if (this.orderBy != null) {
      queryString += ' ORDER BY ' + this.orderBy;
    }
    System.debug(queryString);
    return queryString;
  }

  public void throwError(String message) {
    throw new SelectorException(message);
  }

  public static String whereInClauseBuilder(String field, Set<Id> matchers) {
    Set<String> stringMatchers = (Set<String>) JSON.deserialize(JSON.serialize(matchers), Set<String>.class);
    return whereInClauseBuilder(field, stringMatchers);
  }

  public static String whereInClauseBuilder(String field, Set<String> matchers) {
    if (matchers == null || matchers.size() == 0)
      throw new SelectorException('WhereInClauseBuilder called with no matchers');

    if (matchers != null && matchers.size() == 1)
      return field + ' = \'' + new List<String>(matchers)[0] + '\'';

    String w = field + ' IN (';
    for (Object m : matchers) {
      w += '\'' + m + '\',';
    }
    w = w.removeEnd(',') + ')';
    return w;
  }

  public static String whereNotInClauseBuilder(String field, Set<String> matchers) {
    if (matchers == null || matchers.size() == 0)
      throw new SelectorException('WhereInClauseBuilder called with no matchers');

    if (matchers != null && matchers.size() == 1)
      return field + ' <> \'' + new List<String>(matchers)[0] + '\'';

    String w = field + ' NOT IN (';
    for (Object m : matchers) {
      w += '\'' + m + '\',';
    }
    w = w.removeEnd(',') + ')';
    return w;
  }

  public static String toDateString(Date d) {
    return toDateString(DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)));
  }

  public static String toDateString(DateTime dt) {
    return dt.format('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'');
  }
}
