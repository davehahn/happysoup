public with sharing class Account_Ext {

  public final Id accountId {get; private set;}
  public LegendGallery gallery { get; private set; }

  public Account_Ext(ApexPages.StandardController stdController) {
    this.accountId = stdController.getId();
    this.gallery = new LegendGallery( this.accountId );
  }

  @RemoteAction
  public static LegendGalleryRemoter.ImageWrapper createGalleryImage(String recordData)
  {
    return LegendGalleryRemoter.insertRecord(recordData);
  }


}