@isTest
public class Factory_AccountingVariables {

  public Map<String, AcctSeed__Accounting_Variable__c> glv1s;
  public Map<String, AcctSeed__Accounting_Variable__c> glv2s;
  public Map<String, AcctSeed__Accounting_Variable__c> glv3s;

  public Factory_AccountingVariables()
  {
    glv3s = insertGLV3s();
    glv2s = insertGLV2s();
    glv1s = insertGLV1s( glv3s );
  }

  private static Map<String,AcctSeed__Accounting_Variable__c> insertGLV3s()
  {
    Map<String, AcctSeed__Accounting_Variable__c> variables = new Map<String, AcctSeed__Accounting_Variable__c>();
    variables.put( 'Ontario', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 3',
      Name = 'Ontario',
      Tax_is_Harmonized__c = true,
      Tax_Rate_Provincial__c = 8.0,
      Tax_Rate_Retail__c = 8.0,
      AcctSeed__Active__c = true
    ));
    variables.put( 'Quebec', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 3',
      Name = 'Quebec',
      Tax_is_Harmonized__c = false,
      Tax_Rate_Provincial__c = 9.975,
      Tax_Rate_Retail__c = 9.0,
      AcctSeed__Active__c = true
    ));
    variables.put( 'Others', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 3',
      Name = 'Others',
      AcctSeed__Active__c = true
    ));
    insert variables.values();
    return variables;
  }

  private static Map<String,AcctSeed__Accounting_Variable__c> insertGLV2s()
  {
    Map<String, AcctSeed__Accounting_Variable__c> variables = new Map<String, AcctSeed__Accounting_Variable__c>();
    for( String n : new Set<String>{'Accounting & Administration',
                                    'Business Office',
                                    'IT',
                                    'Logistics',
                                    'Marketing',
                                    'Parts + Service',
                                    'Production',
                                    'Sales',
                                    'Warranty'} )
    {
      variables.put( n, new AcctSeed__Accounting_Variable__c(
        AcctSeed__Type__c =  'GL Account Variable 2',
        Name = n,
        AcctSeed__Active__c = true
      ));
    }
    insert variables.values();
    return variables;
  }

  private static Map<String, AcctSeed__Accounting_Variable__c> insertGLV1s( Map<String, AcctSeed__Accounting_Variable__c> glv3s )
  {
    Map<String, AcctSeed__Accounting_Variable__c> variables = new Map<String, AcctSeed__Accounting_Variable__c>();
    variables.put( 'Retail Barrie', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 1',
      Name = 'Retail Barrie',
      GL_Account_Variable_3__c = glv3s.get('Ontario').Id,
      AcctSeed__Active__c = true
    ));
    variables.put( 'Retail Whitefish', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 1',
      Name = 'Retail Whitefish',
      GL_Account_Variable_3__c = glv3s.get('Ontario').Id,
      AcctSeed__Active__c = true
    ));
    variables.put( 'Retail Montreal', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 1',
      Name = 'Retail Montreal',
      GL_Account_Variable_3__c = glv3s.get('Quebec').Id,
      AcctSeed__Active__c = true
    ));
    variables.put( 'Wholesale', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 1',
      Name = 'Wholesale',
      AcctSeed__Active__c = true
    ));
    variables.put( 'Head Office / Overhead', new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 1',
      Name = 'Head Office / Overhead',
      AcctSeed__Active__c = true
    ));
    insert variables.values();
    return variables;
  }

}