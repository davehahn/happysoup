/**
 * Created by dave on 2019-11-14.
 */

public with sharing class Project_Service
{

  public static List<Case> insertWarrantyPayablesFromCases( List<Case> cases )
  {
    Map<Id, Account> accountMap = buildAccountMap( cases );
    Map<String, Case> caseMap = new Map<String, Case>();
    Map<String, AcctSeed__Project__c> projectMap = new Map<String, AcctSeed__Project__c>();

    for( Case c : cases )
    {
      String id = LGND_Utilities.generateRandomString(6);
      caseMap.put( id, c );
      String accountName = accountMap.containsKey( c.AccountId ) ?
        accountMap.get( c.AccountId ).Name :
        '';
      projectMap.put( id, buildWarrantyPayableFromCase( c, accountName ) );
    }
    insert projectMap.values();

    ProjectTask_Service.insertWarrantyPayableTasksForProjects( projectMap.values() );

    for( String key : caseMap.keySet() )
    {
      caseMap.get( key ).Warranty_ERP__c = projectMap.get( key ).Id;
    }
    return caseMap.values();
  }

  public static AcctSeed__Project__c buildWarrantyPayableFromCase( Case c, String accountName )
  {
    return new AcctSeed__Project__c (
      Name =  accountName.trim(),
      RecordTypeId = gcConstants.idRtProjectWarranty,
      AcctSeed__Account__c = c.AccountId,
      Serial_Number__c = c.Serial_Number__c,
      GMBLASERP__Pricebook__c = c.Price_Book__c
    );
  }

  /**
      ____  ____  _____     ___  _____ _____
     |  _ \|  _ \|_ _\ \   / / \|_   _| ____|
     | |_) | |_) || | \ \ / / _ \ | | |  _|
     |  __/|  _ < | |  \ V / ___ \| | | |___
     |_|   |_| \_\___|  \_/_/   \_\_| |_____|
  **/

  private static Map<Id, Account> buildAccountMap( List<Case> cases )
  {
    Set<Id> acctIds = new Set<Id>();
    for( Case c : cases )
    {
      acctIds.add( c.AccountId );
    }
    return new Map<Id, Account>([SELECT Id, Name FROM Account WHERE ID IN :acctIds]);
  }

  /**
      __  _   _ _____ _   _ _____    _    ____  _     _____  ____
    / _ \| | | | ____| | | | ____|  / \  | __ )| |   | ____/ ___|
   | | | | | | |  _| | | | |  _|   / _ \ |  _ \| |   |  _| \___ \
   | |_| | |_| | |___| |_| | |___ / ___ \| |_) | |___| |___ ___) |
    \__\_\\___/|_____|\___/|_____/_/   \_\____/|_____|_____|____/

   **/

  public class PartnerPartsOrderFromCases_Queue implements Queueable
  {
    public Set<Id> caseIds;

    public PartnerPartsOrderFromCases_Queue()
    {
      this.caseIds = new Set<Id>();
    }

    public PartnerPartsOrderFromCases_Queue( Set<Id> caseIds )
    {
      this.caseIds = caseIds;
    }

    public void execute( QueueableContext context )
    {
      if( this.caseIds == null || this.caseIds.size() == 0 )
        return;

      /* TODO REFACTOR THIS METHOD */
      CreateERPFromClaimCase_ar.createProjectFromCase( this.caseIds );
    }
  }

}