public with sharing class LegendGallery {

  public class GalleryException extends Exception {}

  public class ObjectWrapper {
    public String Id { get; set; }
    public String Name { get; set; }
    public String Default_Image { get; set; }

    public ObjectWrapper(Sobject obj)
    {
      this.Id = String.valueOf( obj.get('Id') );
      try{
        this.Name = String.valueOf( obj.get('Name') );
      }
      catch( Exception e ){}
      try{
        this.Name = 'Case #' + String.valueOf( obj.get('CaseNumber') );
      }
      catch(Exception e){}
      this.Default_Image = String.valueOf( obj.get('Legend_Gallery_Image__c') );
    }
  }

  public Id objectId { get; private set; }
  public String objectType { get; private set; }
  public ObjectWrapper currentObject { get; private set; }
  public Map<String, String> awsSettings { get; private set; }
  public AWS_S3_policy s3Policy { get; private set; }


  public LegendGallery(Id oId)
  {
    this.objectId = oId;
    this.objectType = findObjectType();
    this.awsSettings = s3Settings();
    this.currentObject = doObjectQuery();
    if( !Test.isRunningTest() )
    {
      this.s3Policy = new AWS_S3_Policy( this.awsSettings );
    }
  }

  private String findObjectType()
  {
    Set<String> requiredFields = new Set<String>{'legend_gallery_image__c'};
    Schema.DescribeSObjectResult dr = this.objectId.getSObjectType().getDescribe();
    Set<String> objectFields = dr.fields.getMap().keySet();
    for( String r : requiredFields )
    {
      if( !objectFields.contains( r ) )
      {
        throw new GalleryException( 'Required Fields are missing on the ' + dr.getName() + ' object');
      }
    }
    return dr.getName();
  }

  private ObjectWrapper doObjectQuery()
  {
    String queryString;
    if( this.objectType == 'Case' )
    {
      queryString = 'SELECT Id, CaseNumber, Legend_Gallery_Image__c FROM ';
    }
    else
    {
      queryString = 'SELECT Id, Name, Legend_Gallery_Image__c FROM ';
    }
    queryString += this.objectType + ' WHERE Id = \'' + objectId + '\'';

    //String queryString = 'SELECT Id, Name, Legend_Gallery_Image__c FROM ';
    //queryString += this.objectType + ' WHERE Id = \'' + objectId + '\'';
    //String queryString = LGND_Utilities.getCreatableFieldsSOQL( this.objectType, 'Id = \'' + this.objectId + '\'');
    sObject obj = Database.query( queryString );
    return new ObjectWrapper( obj );
  }

  public static String orgSpecificBucket(){
    Organization org = [SELECT Id, isSandbox FROM Organization LIMIT 1];
    if(org.isSandbox){
      //return 'sandboxlegendboatsmarketing';
      return 'salesforce-image-gallery-sandbox';
    }
    else {
      //return 'legendboatsmarketing';
      return 'salesforce-image-gallery';
    }
  }

  private Map<String,String> s3Settings() {
    Map<String,String> settings = new Map<String, String>();
    //settings.put('AWSCredentialName', org.get('credName') );
    settings.put('Bucket', orgSpecificBucket() );
    settings.put('FileKey', buildFileKey() );
    settings.put('Acl',  'public-read');
    return settings;
  }

  private String buildFileKey() {
    Date now = Date.today();
    return this.objectType + '/' + now.year() + '/' + now.month();
  }


}