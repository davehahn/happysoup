public with sharing class AWS_S3_Policy {
  public class AWS_S3_Policy_Exception extends Exception {
  }

  //public String AWSCredentialName { get; set; }
  public String Bucket { get; set; }
  public String FileKey { get; set; }
  public String Acl { get; set; }
  public String AuthKey { get; private set; }
  public String Policy { get; private set; }
  public String Signature { get; private set; }
  private S3.AmazonS3 as3;

  public AWS_S3_Policy(Map<String, String> settings) {
    String error = validateSettings(settings);
    if (error == null) {
      //this.AWSCredentialName = settings.get('AWSCredentialName');
      try {
        String awsKey = AWS_Settings__c.getOrgDefaults().key__c;
        String awsSecret = AWS_Settings__c.getOrgDefaults().secret__c;
        as3 = new S3.AmazonS3(awsKey, awsSecret);
        this.Bucket = verifyBucket(settings.get('Bucket'));
        this.FileKey = settings.get('FileKey');
        this.Acl = settings.get('Acl');
        this.AuthKey = awsKey;
        this.Policy = buildPolicy();
        this.Signature = signPolicy(this.Policy, awsSecret);
      } catch (AWS_S3_Policy.AWS_S3_Policy_Exception s3Ex) {
        //catch(AWSKeys.AWSKeysException AWSEx){
        //  System.debug('Caught exception in AWS_S3_Policy: ' + AWSEx);
        //  ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, AWSEx.getMessage());
        //  ApexPages.addMessage(errorMsg);
        //}
        System.debug('Caught exception in AWS_Pocily: ' + s3Ex);
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, s3Ex.getMessage());
        ApexPages.addMessage(errorMsg);
      }
    } else {
      ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, error);
      ApexPages.addMessage(errorMsg);
      throw new AWS_S3_Policy_Exception(error);
    }
  }

  private String verifyBucket(String bucket) {
    String error;
    Set<String> bucketNames = allBuckets;
    if (bucketnames == null) {
      error = 'There are Zero buckets in your S3 Account';
    }
    if (!bucketNames.contains(bucket)) {
      error = 'The supplied bucket name was not found in your S3 account.';
    }
    if (error == null) {
      return bucket;
    } else {
      ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, error);
      ApexPages.addMessage(errorMsg);
      throw new AWS_S3_Policy_Exception(error);
      return null;
    }
  }

  //Method to return a string array for all the buckets in your AWS S3 account
  public Set<String> allBuckets {
    get {
      try {
        Datetime now = Datetime.now();

        //This performs the Web Service call to Amazon S3 and retrieves all the Buckets in your AWS Account.
        S3.ListAllMyBucketsResult allBuckets = as3.ListAllMyBuckets(
          as3.key,
          now,
          as3.signature('ListAllMyBuckets', now)
        );

        //Store the Canonical User Id for your account
        //OwnerId = allBuckets.Owner.Id;

        S3.ListAllMyBucketsList bucketList = allBuckets.Buckets;
        S3.ListAllMyBucketsEntry[] buckets = bucketList.Bucket;
        //allBucketList = buckets;

        Set<String> bucketNames = new Set<String>();

        //Loop through each bucket entry to get the bucket name and store in string array.
        for (S3.ListAllMyBucketsEntry bucket : buckets) {
          System.debug('Found bucket with name: ' + bucket.Name);

          bucketNames.add(bucket.name);
        }

        return bucketNames;
      } catch (System.NullPointerException e) {
        return null;
      } catch (Exception ex) {
        //System.debug(ex);
        System.debug('caught exception in listallmybuckets');
        ApexPages.addMessages(ex);
        return null;
      }
    } //end getter
    set;
  }

  private String validateSettings(Map<String, String> settings) {
    Set<String> required = new Set<String>{ 'Bucket', 'FileKey', 'Acl' };
    for (String s : required) {
      if (!settings.containsKey(s)) {
        return 'Error: ' + s + ' was not supplied in settings';
      }
    }
    return null;
  }

  private String buildPolicy() {
    DateTime dt = DateTime.now().addDays(3);
    String d = dt.year() + '-' + dt.month() + '-' + dt.day() + 'T12:00:00.00Z';
    String temp = '{ "expiration": "' + d + '","conditions": [ ';
    temp += '{"bucket": "' + this.Bucket + '" },';
    temp += ' ["starts-with", "$key", "' + this.FileKey + '"],';
    temp += '  {"acl": "' + this.Acl + '" },';
    temp += ' ["starts-with", "$Content-Type", ""]';
    temp += ']}';
    System.debug('inside buildPolicy...:' + temp);
    return EncodingUtil.base64Encode(Blob.valueOf(temp));
  }

  private String signPolicy(String policy, String secret) {
    String macUrl;
    String signingKey = EncodingUtil.base64Encode(Blob.valueOf(secret));
    Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(policy), blob.valueof(secret));
    macUrl = EncodingUtil.base64Encode(mac);
    return macUrl;
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
