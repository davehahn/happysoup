public with sharing class SurveyQuestionResponse {


  public static void triggerHandler(map<Id,SurveyQuestionResponse__c> oldMap,
                                     map<Id,SurveyQuestionResponse__c> newMap,
                                     list<SurveyQuestionResponse__c> listNew,
                                     Boolean boolIsBefore,
                                     Boolean boolIsInsert,
                                     Boolean boolIsUpdate,
                                     Boolean boolIsDelete
                                    )
  {

    if(oldMap == NULL) oldMap = new map<Id,SurveyQuestionResponse__c>();
    if(newMap == NULL) newMap = new map<Id,SurveyQuestionResponse__c>();
    if(listNew == NULL) listNew = new list<SurveyQuestionResponse__c>();

    //Things to do BEFORE
    if(boolIsBefore)
    {
      /*BEFORE INSERT*/
      if(boolIsInsert)
      {
        setNPS_Response(ListNew);
      }

      /*BEFORE UPDATE */
      if(boolIsUpdate)
      {
        setNPS_Response(ListNew);
      }

      /*BEFORE DELETE*/
      //if(boolIsDelete)
      //{
      //}
    }
    else // well.. if it is not before it has to be AFTER
    {
      /*AFTER INSERT*/
      if(boolIsInsert)
      {
       setContactNPS_Score(newMap);

      }

      /*AFTER UPDATE */
      if(boolIsUpdate)
      {
        setContactNPS_Score(newMap);
      }

      /*AFTER DELETE*/
      //if(boolIsDelete)
      //{
      //}
    }

  }

  public static void setNPS_Response(SurveyQuestionResponse__c[] listNew)
  {
    for( SurveyQuestionResponse__c sqr : listNew )
    {
     try
     {
        sqr.NPS_Response__c = Integer.valueOf(sqr.Response__c);
      }
      catch(Exception e){}
    }
  }

  public static void setContactNPS_Score(Map<Id, SurveyQuestionResponse__c> newMap)
  {
    Map<Id, Contact> conts = new Map<Id, Contact>();
    SurveyQuestionResponse__c[] resps = [SELECT Id, SurveyTaker__r.Contact__c, NPS_Response__c
                                           FROM SurveyQuestionResponse__c
                                           WHERE Id IN :newMap.keySet()
                                           AND Survey_Question__r.Contact_NPS_Question__c = true];
    if(resps.size() > 0)
    {
      for( SurveyQuestionResponse__c sqr : resps )
      {
        if(sqr.SurveyTaker__r.Contact__c != null)
        {
          if( conts.containsKey(sqr.SurveyTaker__r.Contact__c) )
          {
            conts.get(sqr.SurveyTaker__r.Contact__c).Current_NPS_Score__c = sqr.NPS_Response__c;
          }
          else
          {
            conts.put(sqr.SurveyTaker__r.Contact__c,
                      new Contact(Id = sqr.SurveyTaker__r.Contact__c, Current_NPS_Score__c = sqr.NPS_Response__c)
                    );
          }
        }
      }
      upsert conts.values();
    }
  }

}