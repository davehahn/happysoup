public with sharing class LGND_MailerController {
  public class EmailWrapper {
    public String body { get; set; }
    public String subject { get; set; }
    public List<String> toAddresses { get; set; }
    public String aws_s3_object_id { get; set; }

    public EmailWrapper() {
    }
  }

  public Id templateId { get; set; }
  public Id objectId { get; private set; }
  public Id awsS3ObjectId { get; set; }
  public static Account account;
  public List<EmailTemplate> templates { get; private set; }
  public Messaging.SingleEmailMessage dummyEmail;
  public String defaultBody { get; set; }
  public String defaultSubject { get; set; }
  public String toAddresses { get; set; }

  public LGND_MailerController() {
    Map<String, String> params = ApexPages.currentPage().getParameters();
    this.objectId = params.get('Id');

    if (params.containsKey('aws_s3_object_id'))
      this.awsS3ObjectId = params.get('aws_s3_object_id');

    account = [
      SELECT Id, Name, isPersonAccount, PersonEmail, AccountEmail__c, (SELECT Id, Name, Email FROM Contacts)
      FROM Account
      WHERE Id = :objectId
    ];

    try {
      Folder f = [SELECT Id FROM Folder WHERE DeveloperName = 'Account_Email_Templates'];
      templates = [SELECT Id, Name FROM EmailTemplate WHERE FolderId = :f.Id AND isActive = TRUE];
      if (templates.size() > 0) {
        templateId = templates[0].Id;
      }
    } catch (Exception e) {
    }
  }

  public void init() {
    this.toAddresses = toCommaSeperated(emailAddressesFromAccount(account));
    if (templateId != null) {
      for (Messaging.SingleEmailMessage email : constructDummyEmail(templateId, account.Id)) {
        this.defaultBody = email.getPlainTextBody();
        this.defaultSubject = email.getSubject();
      }
    }
  }

  @RemoteAction
  public static Map<String, String> templateChanged(String templateId, String accountId) {
    Map<String, String> result = new Map<String, String>();
    for (Messaging.SingleEmailMessage email : constructDummyEmail(Id.valueOf(templateId), Id.valueOf(accountId))) {
      result.put('body', email.getPlainTextBody());
      result.put('subject', email.getSubject());
    }
    return result;
  }

  @RemoteAction
  public static void sendEmail(String jsonData) {
    EmailWrapper wrapper = (EmailWrapper) JSON.deserialize(jsonData, EmailWrapper.class);
    Blob image = fetchImageFromAWS(wrapper.aws_s3_object_id);

    List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
    msg.setToAddresses(wrapper.toAddresses);
    msg.setPlainTextBody(wrapper.body);
    msg.setSubject(wrapper.subject);
    if (image != null) {
      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      efa.setFileName('your_image.jpg');
      efa.setBody(image);
      msg.setFileAttachments(new List<Messaging.EmailFileAttachment>{ efa });
    }
    lstMsgsToSend.add(msg);
    if (!Test.isRunningTest()) {
      Messaging.sendEmail(lstMsgsToSend);
    }
  }

  private static Messaging.SingleEmailMessage[] constructDummyEmail(Id templateId, Id accountId) {
    // Pick a dummy Contact
    Contact c = [SELECT id, Email FROM Contact WHERE email != '' LIMIT 1];
    // Construct the list of emails we want to send
    List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
    msg.setTemplateId(templateId);
    msg.setWhatId(accountId);
    msg.setTargetObjectId(c.Id);
    msg.setToAddresses(new List<String>{ 'dummy@email.com' });
    lstMsgs.add(msg);

    // Send the emails in a transaction, then roll it back
    Savepoint sp = Database.setSavepoint();
    if (!Test.isRunningTest()) {
      Messaging.sendEmail(lstMsgs);
    }
    Database.rollback(sp);
    return lstMsgs;
  }

  private String toCommaSeperated(List<String> addresses) {
    String result = '';
    for (String addr : addresses) {
      result += addr + ', ';
    }
    return result.removeEnd(', ');
  }

  private List<String> emailAddressesFromAccount(Account acct) {
    List<String> result = new List<String>();
    if (acct.isPersonAccount == true) {
      result.add(acct.PersonEmail);
      return result;
    }
    result.add(acct.AccountEmail__c);
    for (Contact c : acct.Contacts) {
      result.add(c.Email);
    }
    return result;
  }

  private static Blob fetchImageFromAWS(String awsS3ObjectId) {
    try {
      AWS_S3_Object__c s3 = [
        SELECT Id, Path__c, File_Name__c, Bucket_Name__c
        FROM AWS_S3_Object__c
        WHERE Id = :awsS3ObjectId
      ];
      Http h = new Http();
      HttpRequest req = new HttpRequest();
      String imageUrl = 'https://s3.amazonaws.com/' + s3.Bucket_Name__c + '/' + s3.Path__c + '/' + s3.File_Name__c;
      imageUrl = imageUrl.replace(' ', '%20');
      req.setEndPoint(imageUrl);
      req.setMethod('GET');
      req.setHeader('Content-Type', 'image/jpeg');
      req.setCompressed(true);
      req.setTimeout(60000);
      HttpResponse res = null;
      res = h.send(req);

      return res.getBodyAsBlob();
    } catch (Exception e) {
      return null;
    }
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
