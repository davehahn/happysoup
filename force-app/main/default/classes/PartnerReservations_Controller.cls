/**
 * Created by dave on 2020-10-05.
 */

public without sharing class PartnerReservations_Controller
{
  @AuraEnabled
  public static Boolean isFactoryStore()
  {
    try {
      return [SELECT Id, Account.Is_Internal__c FROM User WHERE Id = :UserInfo.getUserId() ].Account.Is_Internal__c;
    }
    catch( Exception e )
    {
      AuraHandledException ex = new AuraHandledException('You appear to be logged in as a Non Partner User');
      ex.setMessage('You appear to be logged in as a Non Partner User');
      throw ex;
    }
  }

  @AuraEnabled
  public static String fetchOutstandingBoatOrders()
  {
    return Partner_OutstandingBoatOrders.fetchOrderTypeDetails('boat');
  }

//  @AuraEnabled
//  public static String fetchRetailERPs( String productId )
//  {
//    AcctSeed__Accounting_Variable__c glv1;
//    User u = [ SELECT Id, GL_Account_Variable_1__c FROM User WHERE Id = :UserInfo.getUserId() ];
//    if( u.GL_Account_Variable_1__c == null )
//      throw new AuraHandledException('GLV1 not set on current user.  Contact your Administrator with this error');
//    try
//    {
//      glv1 = [
//        SELECT
//          Id
//        FROM AcctSeed__Accounting_Variable__c
//        WHERE Name = :u.GL_Account_Variable_1__c
//      ];
//    }
//    catch( Exception e )
//    {
//      throw new AuraHandledException('Could not find a GLV1 with name ' + u.GL_Account_Variable_1__c );
//    }
//    return JSON.serialize(
//      fetchAndWrapErpData( glv1.Id, productId )
//    );
//  }

  @AuraEnabled
  public static String createReservation( String partnerErpId, String customerJSON )
  {
    Customer.Person customer =
      (Customer.Person)JSON.deserialize(
        customerJSON, Customer.person.class
      );
    Customer.AccountSaveResult result = customer.upsertRecord();
    if( result.status == 'success' )
    {
      update new AcctSeed__Project__c(
        Id = partnerErpId,
        Reserved_For_Customer_Account__c = result.record.Id
      );
      return JSON.serialize( result.record );
    }
    else
    {
      throw new AuraHandledException( result.messages[0] );
    }
  }

  @AuraEnabled
  public static void cancelReservation( String erpId, String caseId )
  {
    if( erpId != null )
    {
      update new AcctSeed__Project__c(
        Id = erpId,
        Reserved_For_Customer_Account__c = null
      );
    }
    if( caseId != null )
    {
      delete new Case( Id = caseId );
    }
  }

  @AuraEnabled
  public static String checkForPromotions( String productId )
  {
    List<Promotion_Item__c> result = new List<Promotion_Item__c>();
    List<Promotion_Item__c> promoItems = [
      SELECT
        Id,
        Name,
        Promotion__r.Name,
        Promotion__r.Start_Date__c,
        Promotion__r.End_Date__c,
        Promotion__r.Document_Requirements__c,
        Promotion__r.Available_On__c
      FROM Promotion_Item__c
      WHERE Product__c = :productId
      AND Promotion__r.Start_Date__c <= :Datetime.now()
      AND Promotion__r.End_Date__c >= :Datetime.now()
      ORDER BY Promotion__r.End_Date__c ASC
    ];
    for( Promotion_Item__c pi : promoItems )
    {
      if( pi.Promotion__r.Available_On__c != null && pi.Promotion__r.Available_On__c.contains('Reservation') )
      {
        result.add( pi );
      }
    }

    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String createPromotionCase( String jsonData )
  {
    Map<String, String> data = (Map<String, String>)JSON.deserialize(
      jsonData, Map<String, String>.class
    );
    User u = [
      SELECT
        Id,
        AccountId,
        ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    Case c = new Case(
      ContactId = u.ContactId,
      AccountId = u.AccountId,
      RecordTypeId = LGND_Constants.caseRtId_Promotion,
      Promotion_Item__c = data.get('promoItemId'),
      Promotion_Customer_Account__c = data.get('customerId'),
      Promotion_ERP__c = data.get('erpId'),
      Status = 'Pending documentation'
    );
    insert c;
    return JSON.serialize( c );
  }

  @AuraEnabled
  public static void submitCase( String caseId )
  {
    update new Case(
      Id = caseId,
      Status = 'Pending review'
    );
  }



//  private static List<Map<String, Object>> fetchAndWrapErpData( Id glv1Id, String productId )
//  {
//    List<Map<String, Object>> result = new List<Map<String, Object>>();
//    AcctSeed__Project__c[] erps =
//      Project_Selector.allOpenRetailBoatSalesAvailableToReserveByGLV1AndBoatId( glv1Id, Id.valueOf(productId) );
//    for( AcctSeed__Project__c erp : erps )
//    {
//      List<Map<String,Object>> lineItems = new List<Map<String, Object>>();
//      for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r )
//      {
//        Map<String, Object> lineItem = new Map<String, Object>
//        {
//          'name' => mat.AcctSeedERP__Product__r.Name
//        };
//        lineItems.add(
//          new Map<String, Object>{
//            'name' => mat.AcctSeedERP__Product__r.Name
//          }
//        );
//      }
//      Map<String, Object> item = new Map<String, Object>
//      {
//        'id' => erp.Id,
//        'name' => erp.Name,
//        'accountName' => erp.AcctSeed__Account__r.Name,
//        'salesPerson' => erp.Salesperson__r.Name,
//        'serializedItems' => lineItems
//      };
//      result.add( item );
//    }
//    return result;
//  }

}