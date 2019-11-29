public with sharing class ProductFeeExt {

  private ApexPages.StandardController std;
  private final String parentProductId;
  public Product2 currentProduct { get; private set; }
  public Set<String> feeTypes = new Set<String>{'Bank Registration PPSA Fee',
                                           'Documentation Fee',
                                           'Freight',
                                           'License Fee',
                                           'Rigging and Preparation',
                                           'Tire Stewardship Fee'};
  private Set<String> origSelectedIds;
  private List<Product_Fee_Map__c> origMaps;
  private List<Product2> feeProducts;

  public SelectOption[]  availBank {get; set;}
  public SelectOption[]  selectedBank {get; set;}
  public SelectOption[]  availDoc {get; set;}
  public SelectOption[]  selectedDoc {get; set;}
  public SelectOption[]  availFreight {get; set;}
  public SelectOption[]  selectedFreight {get; set;}
  public SelectOption[]  availLicense {get; set;}
  public SelectOption[]  selectedLicense {get; set;}
  public SelectOption[]  availRigging {get; set;}
  public SelectOption[]  selectedRigging {get; set;}
  public SelectOption[]  availTire {get; set;}
  public SelectOption[]  selectedTire {get; set;}


	public ProductFeeExt(ApexPages.StandardController stdCtrl) {
    Boolean editMode = false;
    parentProductId = ApexPages.currentpage().getparameters().get('productId');
    if(parentProductId != null){
      //this needs productId was passed in the params and we have rendered the ProductFeeForm
      editMode = true;
    }
    else {
      // we are simple in the Product view page rendering ProductFeeView inside a product layout
      parentProductId = stdCtrl.getId();
    }
   currentProduct = [SELECT Id, Name,
                      (SELECT Id, Rank__c, Fee_Product__r.Id, Fee_Product__r.Name, Fee_Product__r.Family
                        FROM Parent_Product_Fee_Maps__r
                        ORDER BY Rank__c)
                      FROM Product2
                      WHERE id = :parentProductId];
    origMaps = currentProduct.Parent_Product_Fee_Maps__r;

    if( editmode ){
      //product2 ids which are already associated with currentProduct
      Set<String> origSelectedIds = new Set<String>();
      for( Product_Fee_Map__c pfm : origMaps){
        origSelectedIds.add(pfm.Fee_Product__r.Id);
      }
      List<Product2> availableFeeProducts = [SELECT Id, Name, Family
                                             FROM Product2
                                             WHERE RecordType.Name = 'fees'
                                             AND Id NOT IN :origSelectedIds];
      build_option_groups(origMaps, availableFeeProducts);
    }
	}

  public List<Product2> getFeeProducts() {
    if( feeProducts == null ){
        feeProducts = new List<Product2>();
        Set<String> feeIds = new Set<String>();
        if( origMaps.size() > 0 ){
            for( Product_Fee_Map__c pfm : origMaps ){
                feeIds.add(pfm.Fee_Product__r.Id);
            }
            feeProducts = [SELECT Id, Name, Family,
                           (SELECT Id, UnitPrice, Pricebook2.Name
                            FROM PricebookEntries
                            WHERE isActive = true)
                           FROM Product2
                           WHERE Id = :feeIds
                           ORDER BY Family];
        }
    }
    return feeProducts;
  }

  public PageReference save() {
    List<Product_Fee_Map__c> insertMaps = new List<Product_Fee_Map__c>();
    insertMaps.addAll( pfmListFromSelect( selectedBank ) );
    insertMaps.addAll( pfmListFromSelect( selectedDoc ) );
    insertMaps.addAll( pfmListFromSelect( selectedFreight ) );
    insertMaps.addAll( pfmListFromSelect( selectedLicense ) );
    insertMaps.addAll( pfmListFromSelect( selectedRigging ) );
    insertMaps.addAll( pfmListFromSelect( selectedTire ) );
    try{
      insert insertMaps;
      delete origMaps;
      return new PageReference('/' + currentProduct.Id);
    }
    catch( Exception e){
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Something Is Wrong - ' + e.getMessage() );
      ApexPages.addmessage(myMsg);
      return ApexPages.currentPage();
    }
  }



  /* +++++++++++++++++++++++++++++++++++++++ Privates +++++++++++++++++++++++++++++ */

    private void build_option_groups(List<Product_Fee_Map__c> selected, List<Product2> available) {
      initSelectVars();
      //Make the Select Options for the currently selected fees
      for(Product_Fee_Map__c pfm : selected){
        if( pfm.Fee_Product__r.Family == 'Bank Registration PPSA Fee'){
          selectedBank.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
        if( pfm.Fee_Product__r.Family == 'Documentation Fee'){
          selectedDoc.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
        if( pfm.Fee_Product__r.Family == 'Freight'){
          selectedFreight.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
        if( pfm.Fee_Product__r.Family == 'License Fee'){
          selectedLicense.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
        if( pfm.Fee_Product__r.Family == 'Rigging and Preparation'){
          selectedRigging.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
        if( pfm.Fee_Product__r.Family == 'Tire Stewardship Fee'){
          selectedTire.add( new SelectOption(pfm.Fee_Product__r.Id, pfm.Fee_Product__r.Name) );
        }
      }
      //Make the sSelect Options for Available fees
      for(Product2 p : available){
        if( p.Family == 'Bank Registration PPSA Fee'){
          availBank.add( new SelectOption(p.Id, p.Name) );
        }
        if( p.Family == 'Documentation Fee'){
          availDoc.add( new SelectOption(p.Id, p.Name) );
        }
        if( p.Family == 'Freight'){
          availFreight.add( new SelectOption(p.Id, p.Name) );
        }
        if( p.Family == 'License Fee'){
          availLicense.add( new SelectOption(p.Id, p.Name) );
        }
        if( p.Family == 'Rigging and Preparation'){
          availRigging.add( new SelectOption(p.Id, p.Name) );
        }
        if( p.Family == 'Tire Stewardship Fee'){
          availTire.add( new SelectOption(p.Id, p.Name) );
        }
      }
    }

    private void initSelectVars() {
      availBank = new List<SelectOption>();
      selectedBank = new List<SelectOption>();
      availDoc = new List<SelectOption>();
      selectedDoc = new List<SelectOption>();
      availFreight = new List<SelectOption>();
      selectedFreight = new List<SelectOption>();
      availLicense = new List<SelectOption>();
      selectedLicense = new List<SelectOption>();
      availRigging = new List<SelectOption>();
      selectedRigging = new List<SelectOption>();
      availTire = new List<SelectOption>();
      selectedTire = new List<SelectOption>();
    }

    private List<Product_Fee_Map__c> pfmListFromSelect( List<SelectOption> selectOpts ){
      List<Product_Fee_Map__c> pfms = new List<Product_Fee_Map__c>();
      for( Integer i=0; i < selectOpts.size(); i++ ){
        pfms.add( buildNewPFM( selectOpts[i].getValue(), i) );
      }
      return pfms;
    }

    private Product_Fee_Map__c buildNewPFM(String feeProductId, Integer rank){
      return new Product_Fee_Map__c(
          Rank__c = rank,
          Fee_Product__c = feeProductId,
          Parent_Product__c = currentProduct.id
        );
    }



}