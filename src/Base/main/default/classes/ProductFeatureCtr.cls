public with sharing class ProductFeatureCtr {
  public SelectOption[] selectedConstructionFeatures { get; private set; }
  public SelectOption[] selectedConsoleFeatures { get; private set; }
  public SelectOption[] selectedLivewellFeatures { get; private set; }
  public SelectOption[] selectedSeatingFeatures { get; private set; }
  public SelectOption[] selectedDeckFeatures { get; private set; }
  public SelectOption[] selectedSafetyFeatures { get; private set; }
  public SelectOption[] selectedAdditionalFeatures { get; private set; }

  public SelectOption[] availableConstructionFeatures { get; private set; }
  public SelectOption[] availableConsoleFeatures { get; private set; }
  public SelectOption[] availableLivewellFeatures { get; private set; }
  public SelectOption[] availableSeatingFeatures { get; private set; }
  public SelectOption[] availableDeckFeatures { get; private set; }
  public SelectOption[] availableSafetyFeatures { get; private set; }
  public SelectOption[] availableAdditionalFeatures { get; private set; }

  //public SelectOption[] selectedFeatures { get; private set; }
  //public SelectOption[] allFeatures { get; private set; }
  private final Id productId;
  public final Product2 product { get; private set; }
  private Set<String> originalFeatureIds;
  public Set<String> categories { get; private set; }

	public ProductFeatureCtr() {
		productId = ApexPages.currentPage().getParameters().get('id');
    if(productId != null){
      product = [SELECT Id, Name,
                  (SELECT Id, Feature_Id__r.Category__c, Feature_Id__r.Description__c
                    FROM Product_Feature_Maps__r ORDER BY Rank__c)
                FROM Product2 WHERE Id = :productId];
      initCatagories();
    }
    setUpSelectMenus();
	}

  public PageReference save() {
    try {
      List<Product_Feature_Map__c> origFeatures = product.Product_Feature_Maps__r;
      List<Product_Feature_Map__c> newFeatures = new List<Product_Feature_Map__c>();

      for( Integer i=0; i < selectedConstructionFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedConstructionFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedConsoleFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedConsoleFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedLivewellFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedLivewellFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedSeatingFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedSeatingFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedDeckFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedDeckFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedSafetyFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedSafetyFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }
      for( Integer i=0; i < selectedAdditionalFeatures.size(); i++){
        newFeatures.add( new Product_Feature_Map__c(
          Feature_ID__c = selectedAdditionalFeatures[i].getValue(),
          Product_ID__c = productId,
          Rank__c = i
          )
        );
      }

      delete origFeatures;
      insert newFeatures;
    }
    catch (Exception e)
    {
      String msg=e.getMessage();
      integer pos;

      // if its field validation, this will be added to the messages by default
      if (-1==(pos=msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
      }
    }
    return new PageReference('/' + productId);
        //return null;
  }

  public PageReference cancel(){
    return new PageReference('/' + productId);
  }

  @RemoteAction
  public static Feature__c createNewFeature(String description, String category) {
    Set<String> categories = new Set<String>();
    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : featureCategory.getPicklistValues() ){
      categories.add( ple.getLabel() );
    }
    if( categories.contains(category) ){
      Feature__c f = new Feature__c(description__c = description, category__c = category);
      insert f;
      return f;
    }
    return null;
  }

/**************************************************************************************************
    .______   .______       __  ____    ____  ___   .___________. _______     _______.
    |   _  \  |   _  \     |  | \   \  /   / /   \  |           ||   ____|   /       |
    |  |_)  | |  |_)  |    |  |  \   \/   / /  ^  \ `---|  |----`|  |__     |   (----`
    |   ___/  |      /     |  |   \      / /  /_\  \    |  |     |   __|     \   \
    |  |      |  |\  \----.|  |    \    / /  _____  \   |  |     |  |____.----)   |
    | _|      | _| `._____||__|     \__/ /__/     \__\  |__|     |_______|_______/

***************************************************************************************************/

  private void initCatagories(){
    categories = new Set<String>();
    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : featureCategory.getPicklistValues() ){
      String cat = ple.getLabel();
      categories.add( cat );
    }
    if( selectedConstructionFeatures == null ){
      selectedConstructionFeatures = new List<SelectOption>();
    }
    if( selectedConsoleFeatures == null ){
      selectedConsoleFeatures = new List<SelectOption>();
    }
    if( selectedLivewellFeatures == null ){
      selectedLivewellFeatures = new List<SelectOption>();
    }
    if( selectedSeatingFeatures == null ){
      selectedSeatingFeatures = new List<SelectOption>();
    }
    if( selectedDeckFeatures == null ){
      selectedDeckFeatures = new List<SelectOption>();
    }
    if( selectedSafetyFeatures == null ){
      selectedSafetyFeatures = new List<SelectOption>();
    }
    if( selectedAdditionalFeatures == null ){
      selectedAdditionalFeatures = new List<SelectOption>();
    }
    if( availableConstructionFeatures == null ){
      availableConstructionFeatures = new List<SelectOption>();
    }
    if( availableConsoleFeatures == null ){
      availableConsoleFeatures = new List<SelectOption>();
    }
    if( availableLivewellFeatures == null ){
      availableLivewellFeatures = new List<SelectOption>();
    }
    if( availableSeatingFeatures == null ){
      availableSeatingFeatures = new List<SelectOption>();
    }
    if( availableDeckFeatures == null ){
      availableDeckFeatures = new List<SelectOption>();
    }
    if( availableSafetyFeatures == null ){
      availableSafetyFeatures = new List<SelectOption>();
    }
    if( availableAdditionalFeatures == null ){
      availableAdditionalFeatures = new List<SelectOption>();
    }
  }

  private void setUpSelectMenus(){
    if ( producTid == null ) {
      //selectedFeatures = new List<SelectOption>();
    } else {
      List<Product_Feature_Map__c> pfMaps = product.Product_Feature_Maps__r;
      originalFeatureIds = new Set<String>();
      if( pfMaps.size() > 0 ) {
        List<Feature__c> includedFeatures = new List<Feature__c>();
        for ( Product_Feature_Map__c pfmap : pfMaps ) {
          originalFeatureIds.add(pfmap.Feature_Id__r.Id);
          if( pfmap.Feature_Id__r.Category__c == 'Construction'){
            selectedConstructionFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Console'){
            selectedConsoleFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Livewells'){
            selectedLivewellFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Seating'){
            selectedSeatingFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Decks and Storage'){
            selectedDeckFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Safety'){
            selectedSafetyFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
          }
          if( pfmap.Feature_Id__r.Category__c == 'Additional Features'){
            selectedAdditionalFeatures.add(
              new SelectOption(pfmap.Feature_Id__r.Id, pfmap.Feature_Id__r.description__c)
            );
            }
          }
          // for( Integer i=0; i < features.size(); i++ ){
          //   if( originalFeatureIds.contains( features[i].Id) ){
          //     features.remove(i);
          //   }
          // }
      }
    }
    List<Feature__c> features = [SELECT description__c, Id, Category__c
                                    FROM Feature__c
                                    WHERE Id NOT IN :originalFeatureIds];
    buildAvailableFeatures(features);
  }

  // private List<SelectOption> buildSelect(List<Feature__c> features) {
  //   List<SelectOption> tf = new List<SelectOption>();
  //   for ( Feature__c f : features ) {
  //       tf.add(new SelectOption(f.id, f.description__c));
  //   }
  //   return tf;
  // }

  private void buildAvailableFeatures(List<Feature__c> features){
    for( Feature__c f : features ){
      if( f.Category__c == 'Construction'){
        availableConstructionFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Console'){
        availableConsoleFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Livewells'){
        availableLivewellFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Seating'){
        availableSeatingFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Decks and Storage'){
        availableDeckFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Safety'){
        availableSafetyFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
      if( f.Category__c == 'Additional Features'){
        availableAdditionalFeatures.add(
          new SelectOption(f.Id, f.description__c)
        );
      }
    }
  }




}