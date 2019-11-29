public with sharing class LegendImageGalleryController {

  public LegendGallery lgndGallery { get; set; }
  public Integer imageLimit { get; private set; }

	public LegendImageGalleryController() {
    this.imageLimit = 30;
		String objectId = ApexPages.currentPage().getParameters().get('id');
    if( objectId != null )
    {
      try
      {
        this.lgndGallery = new LegendGallery( objectId );
      }
      catch(Exception e)
      {
        System.debug('Caught exception in AWS_Test: ' + e);
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
        ApexPages.addMessage(errorMsg);
      }
    }
	}

}