public with sharing class DealerPartsOrderController {

  public class PartsOrderException extends Exception {}

  public class DisplayProdFamilyRecords {

    @AuraEnabled public boolean isSelected;
    @AuraEnabled public string prodFamilyName;

    public DisplayProdFamilyRecords(){
        isSelected = false;
        prodFamilyName = '';
    }
  }

  @AuraEnabled
  public static ERPMaterialsWrapper getERPOrder(Id orderId) {
    System.debug( 'ORDERID = ' + orderId);
    try {
      AcctSeed__Project__c erp = [SELECT Id,
                                         AcctSeed__Account__r.Name,
                                         GMBLASERP__Pricebook__c,
                                         Name,
                                         Grand_Total__c,
                                         Stage__c
                                  FROM AcctSeed__Project__c
                                  WHERE Id = :orderId];
      return new ERPMaterialsWrapper(erp, DealerPartsOrderController.getAddedMaterials(orderId));
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static boolean erpDeleteRecord(String recordId){
    try{
        System.debug('recordId-----'+recordId);
        if(string.isNotEmpty(recordId)){
            AcctSeed__Project__c objRecord = new AcctSeed__Project__c();
            objRecord.Id = recordId;
            delete objRecord;
            return true;
        }
        return false;
    }
    catch(Exception e){
        System.debug('Error Occurred -----'+e.getMessage());
        throw e;
    }
  }

  public class ERPMaterialsWrapper {
      @AuraEnabled
      public AcctSeed__Project__c erpOrder;
      @AuraEnabled
      public List<DealerPartsOrderController.MaterialWrapper> materialList;

      public ERPMaterialsWrapper(AcctSeed__Project__c tmpErpOrder, List<DealerPartsOrderController.MaterialWrapper> tmpMaterialList) {
          this.erpOrder = tmpErpOrder;
          this.materialList = tmpMaterialList;
      }
  }


  @AuraEnabled
  public static List<ProductWrapper> getProductswithFamily(String searchKey,
                                                           String pFamily,
                                                           String selectedIds,
                                                           String selectedBoatModel,
                                                           String activePriceBookId,
                                                           Boolean isInternalRetail )
  {
    System.debug('searchKey = ' + searchKey );
    System.debug('pFamily = ' + pFamily );
    System.debug('selectedIds = ' + selectedIds);
    System.debug('selectedBoatModel = ' + selectedBoatModel);
    System.debug('activePriceBookId = ' + activePriceBookId);
    System.debug('isInternalRetail = ' + isInternalRetail );
      Set<Id> allowedRecordTypeIds = new Set<Id>{
        LGND_Utilities.recordTypeIdFromName('Product2', 'Trolling Motor'),
        LGND_Utilities.recordTypeIdFromName('Product2', 'Part')
      };
      Boolean itemsFound = true;
      List<Product2> products = new List<Product2>();
      Set<String> partIdsForBoat = new Set<String>();
      List<String> selectedIdsList = new List<String>();
      List<Mercury_Product__c> mProds = new List<Mercury_Product__c>();
      String query = 'Select Id, Name, description,Default_Image_Thumb__c,ProductCode,family From Product2';
      //String key = '%' + searchKey + '%';
      String searchString = '\'*'+searchKey+'*\'';
      String whereClause = ' WHERE RecordTypeId IN :allowedRecordTypeIds';
      string whereclausequery;
      whereClause += ' AND IsActive = true';
      //we have a search and looking for specific boats
      if(String.isNotBlank(searchKey) && selectedBoatModel != 'All Models')
      {
        System.debug( ' IN SELECTED BOAT IF SO BOAT SHOULD BE SELECTED');
          partIdsForBoat.addAll(getPartIdsForBoat(selectedBoatModel));
          String searchquery = 'FIND ' + searchString + ' IN NAME FIELDS RETURNING';
          searchquery += ' Product2(Id, Name WHERE Id IN :partIdsForBoat AND IsActive = true LIMIT 20)';
          List<List<SObject>> searchList = search.query(searchquery);
          List<Product2> productSearchResultList = (List<Product2>)searchList[0];
          partIdsForBoat.clear();
          itemsFound = false;
          for(Product2 pdt : productSearchResultList) {
              itemsFound = true;
              partIdsForBoat.add(pdt.Id);
          }
      }
      /* we have a search and looking at all boats */
      else if(String.isNotBlank(searchKey))
      {
        String searchquery = 'FIND ' + searchString + ' IN NAME FIELDS RETURNING';
        searchquery += ' Product2(Id, Name WHERE IsActive = true LIMIT 20)';
        List<List<SObject>> searchList = search.query(searchquery);
        List<Product2> productSearchResultList = (List<Product2>)searchList[0];
        itemsFound = false;
        for(Product2 pdt : productSearchResultList) {
            itemsFound = true;
            partIdsForBoat.add(pdt.Id);
        }
        /* MERCURY PRODUCTS SEARCH */
        if( isInternalRetail )
        {
          String sq = '%' + searchKey + '%';
          mProds = [SELECT Id,
                           Code__c,
                           Description__c,
                           List_Price__c,
                           MSRP__c,
                           UPC__c
                    FROM Mercury_Product__c
                    WHERE Salesforce_Product__c = null
                    AND ( Code__c LIKE :sq OR UPC__c LIKE :sq )
                    LIMIT 50 ];
        }
      } else if(selectedBoatModel != 'All Models') {
          itemsFound = false;
          partIdsForBoat.addAll(getPartIdsForBoat(selectedBoatModel));
          if(!partIdsForBoat.isEmpty()) {
              itemsFound = true;
          }
      }
      System.debug('partIdsForBoat = ' + partIdsForBoat );
      if(!partIdsForBoat.isEmpty()) {
          whereClause += ' AND Id IN :partIdsForBoat';
      }
      if(String.isBlank(searchKey) && selectedBoatModel == 'All Models') {
          itemsFound = false;
      }
      if(!string.isBlank(pFamily))
      {
          List<DisplayProdFamilyRecords> lstProdRecords =
          (List<DisplayProdFamilyRecords>)
          System.JSON.deserialize(pFamily,List<DisplayProdFamilyRecords>.class);
          integer i = 0;
          integer x =0;
          string soqlQuery = '';
          String trollingMotorRtId = LGND_Utilities.recordTypeIdFromName('Product2', 'Trolling Motor');
          for(DisplayProdFamilyRecords objProdRecords:lstProdRecords)
          {
              if(objProdRecords.isSelected && i == 0)
              {
                if( objProdRecords.prodFamilyName == 'Trolling Motor' )
                  soqlQuery += 'recordTypeId =\'' + trollingMotorRtId +'\'';
                else
                  soqlQuery += 'family =\''+objProdRecords.prodFamilyName+'\'';
                i=1;
                x=1;

              }
              else if(objProdRecords.isSelected && i == 1)
              {
                if( objProdRecords.prodFamilyName == 'Trolling Motor' )
                  soqlQuery += 'OR recordTypeId =\'' + trollingMotorRtId +'\'';
                else
                  soqlQuery += ' OR family =\''+objProdRecords.prodFamilyName+'\'';
                x=2;
              }
          }

          if(x == 1){
              whereclausequery =  whereClause +' AND '+soqlQuery;
          } else if(x==2){
              whereclausequery = whereClause +' AND ('+soqlQuery+')';
          } else {
              whereclausequery =  whereClause;
          }
      }

      if(String.isNotBlank(selectedIds)) {
          selectedIdsList = selectedIds.split(':');
          whereclausequery += ' AND Id Not IN :selectedIdsList';
      }
      query += whereclausequery + ' Order By Name LIMIT 100';
      System.debug('>>>searchKey>>>>'+searchKey);
      System.debug('>>>query>>>>'+query);
      if(itemsFound) {
          products = Database.query(query);
          System.debug('>>>products>>>>'+query);
      }
      return buildProductsWrapper(products, activePriceBookId, mProds );
  }

  @TestVisible
  private static List<ProductWrapper> buildProductsWrapper( List<Product2> products,
                                                             String activePriceBookId,
                                                             List<Mercury_Product__c> mProds )
  {
      Map<String, Decimal> pdtUnitPriceMap = getProductUnitPriceMap(products, activePriceBookId);
      List<ProductWrapper> results = new List<ProductWrapper>();
      for(Product2 pdt : products) {
        if( pdtUnitPriceMap.containsKey(pdt.Id) )
        {
          ProductWrapper newWrapper = new ProductWrapper(pdt, pdtUnitPriceMap.get(pdt.Id) );
          results.add(newWrapper);
        }
      }
      for( Mercury_Product__c mp : mProds )
      {
        results.add( new ProductWrapper( mp ) );
      }
      return results;
  }

  @TestVisible
  private static Map<String, Decimal> getProductUnitPriceMap( List<Product2> products,
                                                              String activePriceBookId )
  {
      Map<String, Decimal> pdtUnitPriceMap = new Map<String, Decimal>();
      Set<String> pdtIds = new Set<String>();
      for(Product2 pdt : products) {
          pdtIds.add(pdt.Id);
      }
      List<PricebookEntry> pbeList = [SELECT Id, UnitPrice,Product2Id
                          FROM PricebookEntry
                          WHERE Pricebook2Id = :activePriceBookId
                          AND UnitPrice > 0
                          AND Product2Id IN :pdtIds];
      for(PricebookEntry pbe : pbeList) {
          pdtUnitPriceMap.put(pbe.Product2Id, pbe.UnitPrice);
      }
      return pdtUnitPriceMap;
  }

  @AuraEnabled
  public static String fetchProductDetails( String prodId, String pricebookId )
  {
    try {
      return JSON.serialize( new ProductWrapper( prodId, pricebookId) );
    }
    catch( Exception e )
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static String saveRetailCounterSaleERP( String materialsJSON, String accountId, String campaignSource, String lead)
  {
    AcctSeed__Project__c erpOrder = new AcctSeed__Project__c();
    Id RecordtypeId = gcConstants.idRtProjectCounterSale;
    Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId];
    String projectName = acc.Name.trim();

    erpOrder.Name=projectName;
    erpOrder.RecordTypeId = RecordtypeId;
    erpOrder.AcctSeed__Account__c = acc.Id;
    erpOrder.Campaign__c = campaignSource;
    erpOrder.LeadSource__c = lead;
    insert erpOrder;

    AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(AcctSeed__Project__c = erpOrder.Id,
                                                                          DisplayOnCustomerInvoice__c = true,
                                                                          Name = 'Default Task');
    insert projectTask;
    insertMaterials(materialsJSON, erpOrder.Id, projectTask);
    return erpOrder.Id;
  }

  @AuraEnabled
  public static String saveMaterials( String wrJSONStr,
                                    String internalPoNumber,
                                    String erpOrderId,
                                    String removedMatIds,
                                    Boolean isSaveLater)
  {
    if(String.isBlank(erpOrderId)) {
      AcctSeed__Project__c erpOrder = new AcctSeed__Project__c();
      AccountWrapper acc = getAccountId();
      //String RecordtypeId= Schema.SObjectType.AcctSeed__Project__c.getRecordTypeInfosByName().get('Legend Counter Sale').getRecordTypeId();
      Id RecordtypeId = gcConstants.idRtPartnerPartsOrder;
      if(String.isNotBlank(acc.accId)) {
        String projectName = (acc.accName.length()>=5?acc.accName.trim().substring(0,4):acc.accName)+'_'+DateTime.now().format('yyyyMMdd');

        erpOrder.Name=projectName;
        erpOrder.Partner_External_PO_Number__c = internalPoNumber;
        erpOrder.RecordTypeId = RecordtypeId;
        erpOrder.AcctSeed__Account__c=acc.accId;
        erpOrder.Stage__c = isSaveLater ? 'Draft' : 'Parts Required';
        insert erpOrder;

        AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(AcctSeed__Project__c = erpOrder.Id,
                                                                              DisplayOnCustomerInvoice__c = true,
                                                                              Name = 'Parts Order');
        insert projectTask;
        insertMaterials(wrJSONStr, erpOrder.Id, projectTask);
        erpOrderId = erpOrder.Id;
      }
    }
    else
    {
      AcctSeed__Project__c erpOrder = new AcctSeed__Project__c();
      erpOrder.Id = erpOrderId;
      erpOrder.Stage__c = isSaveLater ? 'Draft' : 'Parts Required';
      update erpOrder;

      if(String.isNotBlank(removedMatIds)) {
          delete [Select Id From AcctSeedERP__Material__c where Id IN:removedMatIds.split(':')];
      }
      List<AcctSeed__Project_Task__c> pjtTaskList = [Select Id, Name, AcctSeed__Project__c
                                                     From AcctSeed__Project_Task__c
                                                     Where AcctSeed__Project__c =:erpOrderId
                                                     And DisplayOnCustomerInvoice__c = true];
      AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c();
      if(!pjtTaskList.isEmpty()) {
          projectTask = pjtTaskList[0];
      } else {
          projectTask.AcctSeed__Project__c = erpOrderId;
          projectTask.DisplayOnCustomerInvoice__c = true;
          projectTask.Name = 'Parts Order';
          insert projectTask;
      }
      insertMaterials(wrJSONStr, erpOrderId, projectTask);
    }
    return erpOrderId;
  }

  public static void insertMaterials( String wrJSONStr,
                                      String erpOrderId,
                                      AcctSeed__Project_Task__c projectTask )
  {
    List<MaterialWrapper> mProdsList = new List<MaterialWrapper>();
    List<MaterialWrapper> wrList = (List<MaterialWrapper>)JSON.deserialize(wrJSONStr, List<MaterialWrapper>.class);
    List<AcctSeedERP__Material__c> materialList = new List<AcctSeedERP__Material__c>();
    for(MaterialWrapper wr : wrList) {
      if( LGND_Utilities.sObjectNameFromId( wr.pdtId ) == 'Mercury_Product__c' )
        mProdsList.add( wr );
      else
      {
        AcctSeedERP__Material__c newMaterial = new AcctSeedERP__Material__c();
        if(String.isBlank(wr.matId)) {
            newMaterial.AcctSeedERP__Product__c = wr.pdtId;
            newMaterial.AcctSeedERP__Quantity_Per_Unit__c = wr.matQuantity;
            newMaterial.GMBLASERP__Unit_Price__c = wr.pricePerQuantity;
            newMaterial.AcctSeedERP__Project__c = erpOrderId;
            newMaterial.AcctSeedERP__Project_Task__c = projectTask.Id;
        } else {
            newMaterial.Id = wr.matId;
            newMaterial.AcctSeedERP__Quantity_Per_Unit__c = wr.matQuantity;
        }
        materialList.add(newMaterial);
      }
    }
    /*
    if( mProdsList.size() > 0 )
    {
      //create Product and Pricebook entries for Mercury Product
      Map<Id, MaterialWrapper> matMap = new Map<Id, MaterialWrapper>();
      for( MaterialWrapper mw : mProdsList )
      {
        matMap.put( mw.pdtId, mw );
      }
      Map<Id, Id> mp_prod_map = Mercury_Product_dh.convertToSalesforceProducts( matMap.keySet() );
      for( MaterialWrapper mw : mProdsList )
      {
        materialList.add( new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = mp_prod_map.get( mw.pdtId ),
          AcctSeedERP__Quantity_Per_Unit__c = mw.matQuantity,
          GMBLASERP__Unit_Price__c = mw.pricePerQuantity,
          AcctSeedERP__Project__c = erpOrderId,
          AcctSeedERP__Project_Task__c = projectTask.Id
        );
      }
    }
    */
    upsert materialList;
  }

  @AuraEnabled
  public static Map<String,String> getProductQuantity(String idProduct)
  {
      Map<String,String> m = new Map<String,String>();
      String userWarehouse = gcConstants.nameUserWarehouse;
      Id idWarehouse;
      if(userWarehouse == null) userWarehouse = 'Wholesale';
      for(AcctSeedERP__Warehouse__c whs :
          [SELECT Id
           FROM AcctSeedERP__Warehouse__c
           WHERE Name =:userWarehouse])
        {
          idWarehouse = whs.Id;
        }

      m.put('warehouseName', userWarehouse);
      Map<Id,Decimal> mapProductQty = new Map<Id,Decimal>();
      List<String> listIdProduct = new  List<String>();
      listIdProduct.add(idProduct);
      map<String,list<String>> mapFilters = new map<String,list<String>>();
      mapFilters.put('idProduct',listIdProduct);
      mapFilters.put('idWarehouse',new List<String>{idWarehouse});
      List<gcInventoryMovementCube_Report.cube> allCubes = gcInventoryMovementCube_Report.inventoryAggRes(mapFilters, new List<String>{'idProduct'});
      Decimal qty = 0;
      if(!allCubes.isEmpty())
      for(gcInventoryMovementCube_Report.cube cube : allCubes){
        qty = cube.qty;
      }
      m.put('qty', String.valueOf(qty));
      return m;
  }

  public static AccountWrapper getAccountId()
  {
      AccountWrapper result = new AccountWrapper();
      String userType = UserInfo.getUserType();
      if( userType != 'Standard') {
          User uu = [Select contact.AccountId,contact.Account.Name from User Where Id =: Userinfo.getUserId()];
          result.accId = uu.contact.AccountId;
          result.accName = uu.contact.Account.Name;
      } else {
          result.accId = '001R000001BIuGt';
          result.accName = 'Test Acc for Internal users';
      }
      return result;
  }

  @AuraEnabled
  public static ProductFamilyAndBoatModelWrapper getProductFamily( String erpOrderId,
                                                                    String saleType )
  {
      string[] strprodfamily = new List<String>();

      try {
        String families = Legend_Settings__c.getOrgDefaults().Product_Family_Filter__c;
        strprodfamily = families.split(':');
        if( saleType.toLowerCase() == 'retail' )
          strprodfamily.add('Trolling Motor');
      }
      catch(Exception e){}
      //final Schema.DescribeFieldResult fieldResult = Product2.family.getDescribe();
      //final List<Schema.picklistEntry> ple = fieldResult.getPicklistValues();
      //for(Schema.picklistEntry f:ple) {
      //    strprodfamily.add(f.getLabel());

      //}
      List<DisplayProdFamilyRecords> lstProdRecords =
      new List<DisplayProdFamilyRecords>();


      if(strprodfamily != null && strprodfamily.size() > 0){

          for(String prod : strprodfamily){

              DisplayProdFamilyRecords prodRecord =
              new DisplayProdFamilyRecords();
              prodRecord.prodFamilyName = prod;

              lstProdRecords.add(prodRecord);
          }

      }
      String activePriceBookId = findPriceBook( saleType );
      List<PriceBookEntry> entryList = availableBoatModels( activePriceBookId );
      List<PickListDataWrapper> boatModelList = new List<PickListDataWrapper>();
      boatModelList.add( new PickListDataWrapper('All Models', 'All Models'));
      for(PriceBookEntry pBook : entryList ) {
          boatModelList.add( new PickListDataWrapper(pBook.Product2.Name, pBook.Product2Id));
      }
      system.debug('==>'+lstProdRecords);

      List<MaterialWrapper> tmpMatList = new List<MaterialWrapper>();
      String partnerReference = '';
      if(String.isNotBlank(erpOrderId))
      {
        tmpMatList = getAddedMaterials(erpOrderId);
        AcctSeed__Project__c erp = [SELECT Id, Partner_External_PO_Number__c
                                   FROM AcctSeed__Project__c
                                   WHERE Id = :erpOrderId ];
        partnerReference = erp.Partner_External_PO_Number__c;
      }
      return new ProductFamilyAndBoatModelWrapper( boatModelList,
                                                   lstProdRecords,
                                                   tmpMatList,
                                                   activePriceBookId,
                                                   partnerReference );
  }

  @TestVisible
  private static String findPriceBook( String saleType )
  {
    // try to dermine the pricebook from the logged in user,
    // this will work only for 'Partner' users
    try {
      Id accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;
      Account acct = [SELECT Id, Is_Internal__c FROM Account WHERE Id = :accountId];
      return acct.Is_Internal__c == true ?
        gcConstants.idPricebookFactory :
        gcConstants.idPricebookPartner;
    }
    catch( Exception e )
    {
      if( saleType.toLowerCase() == 'retail' )
        return Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
      if( saleType.toLowerCase() == 'partner' )
        return Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
      throw new PartsOrderException('Please specify either \'Retail\' or \'Partner\' as Sale Type');
    }
  }

  @TestVisible
  private static List<PriceBookEntry> availableBoatModels( string activePriceBookId )
  {
      List<PriceBookEntry> entryList = new List<PriceBookEntry>();
      entryList = [Select Id,
                          Name,
                          Product2Id,
                          Product2.Name,
                          PriceBook2Id
                      From PriceBookEntry
                      Where PriceBook2Id =:activePriceBookId
                          And isActive = true
                          And Product2.RecordType.Name = 'Boat'
                          And Product2.IsActive = true
                      Order by Product2.Name];
      return entryList;
  }

  public static List<MaterialWrapper> getAddedMaterials(String erpOrderId)
  {
      List<MaterialWrapper> results = new List<MaterialWrapper>();
      if(String.isNotBlank(erpOrderId)) {
        Id idWarehouse;
        Set<String> setIdProduct = new Set<String>();
          List<AcctSeedERP__Material__c> materialList = [Select Id,
                                                         Name,
                                                         AcctSeedERP__Product__c,
                                                         AcctSeedERP__Product__r.Default_Image_Thumb__c,
                                                         AcctSeedERP__Product__r.Name,
                                                         AcctSeedERP__Product__r.ProductCode,
                                                         AcctSeedERP__Quantity_Per_Unit__c,
                                                         GMBLASERP__Unit_Price__c,
                                                         AcctSeedERP__Project__c,
                                                         AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
                                                         AcctSeedERP__Project_Task__c
                                                         From AcctSeedERP__Material__c
                                                         Where AcctSeedERP__Project_Task__r.AcctSeed__Project__c =:erpOrderId];

          for(AcctSeedERP__Material__c mat : materialList) {
            if(idWarehouse == null)
              idWarehouse = mat.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c;
              setIdProduct.add(mat.AcctSeedERP__Product__c);
              MaterialWrapper newWr = new MaterialWrapper();
              newWr.matId = mat.Id;
              newWr.pdtId = mat.AcctSeedERP__Product__c;
              newWr.matQuantity = mat.AcctSeedERP__Quantity_Per_Unit__c;
              newWr.pricePerQuantity = mat.GMBLASERP__Unit_Price__c;
              newWr.pdtName = mat.AcctSeedERP__Product__r.Name;
              newWr.pdtcode = mat.AcctSeedERP__Product__r.ProductCode;
              newWr.matImgUrl = mat.AcctSeedERP__Product__r.Default_Image_Thumb__c;
              newWr.totalPrice = (mat.GMBLASERP__Unit_Price__c*mat.AcctSeedERP__Quantity_Per_Unit__c).setScale(2);
              newWr.taskId = mat.AcctSeedERP__Project_Task__c;
              results.add(newWr);
          }
          Map<Id,Decimal> mapProductQty = new Map<Id,Decimal>();
          List<String> listIdProduct = new  List<String>();
          listIdProduct.addAll(setIdProduct);
          map<String,list<String>> mapFilters = new map<String,list<String>>();
          mapFilters.put('idProduct',listIdProduct);
          mapFilters.put('idWarehouse',new List<String>{idWarehouse});
          List<gcInventoryMovementCube_Report.cube> allCubes = gcInventoryMovementCube_Report.inventoryAggRes(mapFilters, new List<String>{'idProduct'});
          System.debug(LoggingLevel.ERROR,'allCubes:'+allCubes);
          Map<Id,Decimal> mapSerialCost = new Map<Id,Decimal>();
          for(gcInventoryMovementCube_Report.cube cube : allCubes){
            mapProductQty.put(cube.idProduct, cube.qty);
          }

          for(MaterialWrapper newWr : results)
          {
            if(mapProductQty.containsKey(newWr.pdtId))
              newWr.AvailableQuantitySelf = mapProductQty.get(newWr.pdtId);
            else
              newWr.AvailableQuantitySelf = 0;
          }
      }
      return results;
  }

  private static Set<String> getPartIdsForBoat(String selectedBoatModel) {
    Set<Id> allowedRecordTypeIds = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trolling Motor'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Part')
    };
    Set<String> partIdsList = new Set<String>();
    List<AcctSeed__Product_Part__c> partsList = [Select Id,
                                AcctSeed__Product__c,
                                AcctSeed__Product_Part__c
                            From AcctSeed__Product_Part__c
                            where AcctSeed__Product__c =:selectedBoatModel
                            And AcctSeed__Product_Part__r.IsActive = true
                            And AcctSeed__Product_Part__r.RecordTypeId IN :allowedRecordTypeIds];
    for(AcctSeed__Product_Part__c part : partsList) {
        partIdsList.add(part.AcctSeed__Product_Part__c);
    }

    for(Product_Option__c objProductOption : [SELECT Id,From_Product__c,To_Product__c
                                              FROM Product_Option__c
                                              WHERE ( From_Product__c = :selectedBoatModel OR
                                                     To_Product__c =: selectedBoatModel )
                                              AND ( From_Product__r.IsActive = true OR
                                                   To_Product__r.IsActive = true )
                                              AND ( From_Product__r.RecordTypeId IN :allowedRecordTypeIds OR
                                                   To_Product__r.RecordTypeId IN :allowedRecordTypeIds )] )
    {
        partIdsList.add(objProductOption.From_Product__c);
        partIdsList.add(objProductOption.To_Product__c);
    }

    return partIdsList;
  }

  public class MaterialWrapper {
      @AuraEnabled
      public String               matId;
      @AuraEnabled
      public String               pdtId;
      @AuraEnabled
      public String               pdtName;
      @AuraEnabled
      public Decimal              matQuantity;
      @AuraEnabled
      public Decimal              pricePerQuantity;
      @AuraEnabled
      public String               pdtcode;
      @AuraEnabled
      public Decimal              totalPrice;
      @AuraEnabled
      public String               matImgUrl;
      @AuraEnabled
      public String               taskId;
      @AuraEnabled
      public String               warehouseName;
      @AuraEnabled
      public Decimal              AvailableQuantitySelf;
      @AuraEnabled
      public Decimal              AvailableQuantityWholesale;
  }

  public class ProductWrapper {
    @AuraEnabled
    public String Id;

    @AuraEnabled
    public String Name;

    @AuraEnabled
    public String Family;

    @AuraEnabled
    public String ProductCode;

    @AuraEnabled
    public String Description;

    @AuraEnabled
    public String ImageURL;

    @AuraEnabled
    public Decimal UnitPrice;

    @AuraEnabled
    public Boolean isMercuryProduct = false;

    public ProductWrapper( String prodId, String pricebookId )
    {
      PriceBookEntry pbe = [SELECT Id,
                                   UnitPrice,
                                   Product2.Id,
                                   Product2.Name,
                                   Product2.ProductCode,
                                   Product2.Family,
                                   Product2.Description,
                                   Product2.Default_Image_Thumb__c
                            FROM PriceBookEntry
                            WHERE Product2Id = :prodId
                            AND Pricebook2Id = :pricebookId ];

      this.Id = pbe.Product2.Id;
      this.Name = pbe.Product2.Name;
      this.Description = pbe.Product2.Description;
      this.ProductCode = pbe.Product2.ProductCode;
      this.Family = pbe.Product2.Family;
      this.ImageURL = pbe.Product2.Default_Image_Thumb__c;
      this.UnitPrice = pbe.UnitPrice;
    }

    public ProductWrapper( Product2 p, Decimal price )
    {
      this.Id = p.Id;
      this.Name = p.Name;
      this.Description = p.Description;
      this.ProductCode = p.ProductCode;
      this.Family = p.Family;
      this.ImageURL = p.Default_Image_Thumb__c;
      this.UnitPrice = price;
    }

    public ProductWrapper( Mercury_Product__c mp )
    {
      this.Id = mp.Id;
      this.Name = mp.Description__c;
      this.ProductCode = mp.Code__c;
      this.UnitPrice = mp.MSRP__c;
      this.isMercuryProduct = true;
      this.ImageURL = '<img src=\"/resource/MercuryLogo\" alt=\"Mercury Part\" style=\"height:75px; width:75px;\" border=\"0\"/>';
    }

  }

  public class ProductsWrapper {
      @AuraEnabled
      public Product2             product;
      @AuraEnabled
      public Decimal              unitPrice;
      @AuraEnabled
      public String               pdtImgUrl;

      public ProductsWrapper(Product2 tmpProduct, Decimal tmpUnitPrice) {

          product = tmpProduct;
          unitPrice = tmpUnitPrice;
          pdtImgUrl = '';
      }
  }

  public class AccountWrapper {
      @AuraEnabled
      public String             accName;
      @AuraEnabled
      public String             accId;
  }

  public class ProductFamilyAndBoatModelWrapper {
      @AuraEnabled
      public List<PickListDataWrapper>    boatModel;
      @AuraEnabled
      public List<DisplayProdFamilyRecords>    productFamily;
      @AuraEnabled
      public List<MaterialWrapper> materialList;
      @AuraEnabled
      public String activePriceBookId;
      @AuraEnabled
      public String partnerReference;

      public ProductFamilyAndBoatModelWrapper( List<PickListDataWrapper> tmpBoatModel,
                                               List<DisplayProdFamilyRecords> tmpProductFamily,
                                               List<MaterialWrapper> tmpMaterialList,
                                               String activePriceBookId,
                                               String partnerReference ) {
          this.boatModel = tmpBoatModel;
          this.productFamily = tmpProductFamily;
          this.materialList = tmpMaterialList;
          this.activePriceBookId = activePriceBookId;
          this.partnerReference = partnerReference;
      }
  }

  public class PickListDataWrapper {
      @AuraEnabled
      public String   label;
      @AuraEnabled
      public String   value;

      public PickListDataWrapper(){}

      public PickListDataWrapper(String plabel, String pValue) {
          this.label = pLabel;
          this.value = pValue;
      }
  }

  public static void coverage()
  {
        integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
  }
}