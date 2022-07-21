@isTest
private class LGND_Mailer_Test {
  static Account acct;
  static User usr;
  static String folder_name = 'Account_Email_Templates';
  static Folder folder;
  static List<EmailTemplate> emailTemplates;

  static {
    usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    acct = new Account(FirstName = 'Test', LastName = 'Account', AccountEmail__c = 'test@email.com');
    insert acct;
  }

  @future
  public static void init() {
    folder = [SELECT Id FROM Folder WHERE DeveloperName = :folder_name];
    emailTemplates = new List<EmailTemplate>();
    for (Integer i = 0; i < 3; i++) {
      emailTemplates.add(
        new EmailTemplate(
          developerName = 'test_email_template_' + String.valueOf(i),
          isActive = true,
          Name = 'test email template ' + String.valueOf(i),
          TemplateType = 'text',
          FolderId = folder.Id,
          Subject = 'test subject ' + String.valueOf(i)
        )
      );
    }
    insert emailTemplates;
  }

  @isTest
  static void coverage_Test() {
    LGND_MailerController.coverage();
  }

  @isTest
  static void constructor_test() {
    System.runAs(usr) {
      Test.startTest();
      init();
      PageReference pageRef = Page.LGND_Mailer;
      pageRef.getParameters().put('id', acct.Id);
      Test.setCurrentPage(pageRef);
      LGND_MailerController mailer = new LGND_MailerController();
      Test.stopTest();

      System.assertEquals(acct.Id, mailer.objectId);
      //System.assert(mailer.templates.size() > 0 );
    }

  }

  @isTest
  static void templateChanged_Test() {
    System.runAs(usr) {
      Test.startTest();
      init();
      PageReference pageRef = Page.LGND_Mailer;
      pageRef.getParameters().put('id', acct.Id);
      Test.setCurrentPage(pageRef);
      LGND_MailerController mailer = new LGND_MailerController();
      Contact c = new Contact(FirstName = 'test', LastName = 'contact', Email = 'test@contact.com');
      insert c;
      EmailTemplate et = [SELECT Id FROM EmailTemplate LIMIT 1];
      Map<String, String> templateData = LGND_MailerController.templateChanged(et.Id, acct.Id);
      Test.stopTest();
    }
  }

  @isTest
  static void sendEmail_Test() {
    System.runAs(usr) {
      Test.startTest();
      init();
      PageReference pageRef = Page.LGND_Mailer;
      pageRef.getParameters().put('id', acct.Id);
      Test.setCurrentPage(pageRef);
      LGND_MailerController mailer = new LGND_MailerController();
      String json = '{\"body\":\"I am the email body\",\"toAddresses\":[\"dave@davehahn.me\"],\"subject\":\"I am the Subject\"}';
      LGND_MailerController.sendEmail(json);
      Test.stopTest();
    }
  }
}
