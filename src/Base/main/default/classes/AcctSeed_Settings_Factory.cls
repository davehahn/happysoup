@isTest( seeAllData=true )
public with sharing class AcctSeed_Settings_Factory {

  /*
  .___________.    ___      ___   ___     ________    ______   .__   __.  _______
  |           |   /   \     \  \ /  /    |       /   /  __  \  |  \ |  | |   ____|
  `---|  |----`  /  ^  \     \  V  /     `---/  /   |  |  |  | |   \|  | |  |__
      |  |      /  /_\  \     >   <         /  /    |  |  |  | |  . `  | |   __|
      |  |     /  _____  \   /  .  \       /  /----.|  `--'  | |  |\   | |  |____
      |__|    /__/     \__\ /__/ \__\     /________| \______/  |__| \__| |_______|
  */

  public static AcctSeed__Accounting_Variable__c getTaxZone(String name)
  {
    try {
      return [SELECT Id, Name, AcctSeed__Type__c, Tax_is_Harmonized__c, Tax_Rate_Provincial__c
              FROM AcctSeed__Accounting_Variable__c
              WHERE Name = :name];
    }
    catch(Exception e)
    {
      return createTaxZone('Ontario', true, 8.0);
    }
  }

  public static AcctSeed__Accounting_Variable__c createTaxZone( String provName,
                                                                Boolean isHarmonized,
                                                                Decimal provTaxRate )
  {
    AcctSeed__Accounting_Variable__c taxZone = new AcctSeed__Accounting_Variable__c(
      Name = provName,
      AcctSeed__Active__c = true,
      AcctSeed__Type__c = 'GL Account Variable 3',
      Tax_Rate_Provincial__c = provTaxRate,
      Tax_is_Harmonized__c = isHarmonized
    );
    insert taxZone;
    return taxZone;
  }

  /*
  ____    __    ____  ___      .______       _______  __    __    ______    __    __       _______. _______
  \   \  /  \  /   / /   \     |   _  \     |   ____||  |  |  |  /  __  \  |  |  |  |     /       ||   ____|
   \   \/    \/   / /  ^  \    |  |_)  |    |  |__   |  |__|  | |  |  |  | |  |  |  |    |   (----`|  |__
    \            / /  /_\  \   |      /     |   __|  |   __   | |  |  |  | |  |  |  |     \   \    |   __|
     \    /\    / /  _____  \  |  |\  \----.|  |____ |  |  |  | |  `--'  | |  `--'  | .----)   |   |  |____
      \__/  \__/ /__/     \__\ | _| `._____||_______||__|  |__|  \______/   \______/  |_______/    |_______|
  */

  public static AcctSeedERP__Warehouse__c getWarehouse(String name)
  {
    try {
      return [SELECT Id,
                     Name,
                     City__c,
                     Country__c,
                     GL_Account_Variable_3__c,
                     Postal_Code__c,
                     State__c,
                     Street__c
             FROM AcctSeedERP__Warehouse__c
             WHERE Name = :name
             LIMIT 1];
    }
    catch(Exception e)
    {
      return createWarehouse( 'Whitefish',
                              '4805 Regional Road 55',
                              'Whitefish',
                              'ON',
                              'Canada',
                              'P0M 3E0',
                              null);
    }
  }

  public static AcctSeedERP__Warehouse__c createWarehouse( String name,
                                                          String street,
                                                          String city,
                                                          String state,
                                                          String country,
                                                          String postal,
                                                          Id taxZoneId )
  {
    AcctSeedERP__Warehouse__c wh = new AcctSeedERP__Warehouse__c(
      Name = name,
      Street__c = street,
      City__c = city,
      State__c = state,
      Country__c = country,
      Postal_Code__c = postal,
      GL_Account_Variable_3__c = taxZoneId == null ? getTaxZone('Ontario').Id : taxZoneId
    );
    insert wh;
    return wh;
  }



}