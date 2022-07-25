public with sharing class SurveyTestingUtil {
  public String surveyId { get; set; }
  public List<String> questionIds { get; set; }
  public String contactId { get; set; }
  public String surveyTakerId { get; set; }
  public String contactId2 { get; set; }

  public SurveyTestingUtil() {
    questionIds = new List<String>();
    createTestSurvey();
    createTestQuestions();
    createTestContact();
    createSurveyTaker();
    createTestResponses();
  }

  private static testMethod void testConstructor() {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Survey_Question__c sq = [
      SELECT id, NPS_Detractor_Count__c
      FROM Survey_Question__c
      WHERE id = :tu.questionIds[4]
      LIMIT 1
    ];
    System.assert(tu.surveyId != null);
    System.assertEquals(1, sq.NPS_Detractor_Count__c);
  }

  private void createSurveyTaker() {
    SurveyTaker__c st = new SurveyTaker__c();
    st.Contact__c = contactId;
    st.Survey__c = surveyId;
    st.Taken__c = 'false';
    insert st;
    surveyTakerId = st.Id;
  }

  public void createTestSurvey() {
    Survey__c s = new Survey__c();
    s.Name = 'Testing Survey';
    s.Submit_Response__c = 'empty';
    insert s;
    surveyId = s.Id;
  }

  public void createTestQuestions() {
    questionIds.add(createQuestion(0));
    questionIds.add(createQuestion(1));
    questionIds.add(createQuestion(2));
    questionIds.add(createQuestion(3));
    questionIds.add(createQuestion(4));
  }

  private String createQuestion(Integer i) {
    Survey_Question__c q = new Survey_Question__c();
    String t = getType(i);
    q.Name = 'Testing Question';
    q.Survey__c = surveyId;
    q.Type__c = t;
    q.Contact_NPS_Question__c = t.contains('NPS') ? true : false;
    q.Choices__c = getChoices();
    q.Question__c = 'Testing Question question';
    q.OrderNumber__c = i;
    q.Required__c = true;
    insert q;
    return q.id;
  }

  private void createTestContact() {
    Contact c = new Contact();
    c.LastName = 'Doe';
    c.FirstName = 'John';
    c.Email = 'surveyAppUser@hotmail.com';
    insert c;
    contactId = c.Id;

    Contact c2 = new Contact();
    c2.LastName = 'Doe2';
    c2.FirstName = 'John2';
    c2.Email = 'surveyAppUser2@hotmail.com';
    insert c2;
    contactId2 = c2.Id;
  }

  private String createTestResponses() {
    SurveyQuestionResponse__c r = new SurveyQuestionResponse__c();
    r.Response__c = '4';
    Survey_Question__c sq = [SELECT id FROM Survey_Question__c WHERE id = :questionIds[4] LIMIT 1];
    r.Survey_Question__c = sq.id;
    r.SurveyTaker__c = surveyTakerId;
    insert r;
    return 'true';
  }

  private String getType(Integer i) {
    if (i == 1)
      return 'Multi-Select--Vertical';
    else if (i == 2)
      return 'Single Select--Vertical';
    else if (i == 3)
      return 'Free Text';
    else if (i == 4)
      return 'NPS--Horizontal';
    else
      return 'Single Select--Horizontal';
  }
  private String getChoices() {
    //return 'one\ntwo\nthree\n';
    return '1\n2\n3\n4\n5\n6\n7\n8\n9\n10';
  }
}
