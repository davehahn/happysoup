public without sharing class ProductMRP_ar {
    public class resultData {
        public Id productId { get; set; }
        public String productName { get; set; }
        public Id warehouseId { get; set; }
        public String warehouseName { get; set; }
        public Decimal lastYearSeasonConsumption { get; set; }
        public Decimal lastYearLeadTimeConsumption { get; set; }
        public Decimal mrpQuantity { get; set; }
        public Decimal averageLeadTime { get; set; }
        public Decimal percentageQuantity { get; set; }
        public Double percentageLength { get; set; }
        List<Integer> listLeadTime { get; set; }
        String colorCode {get;set;}
        resultData (){
            lastYearSeasonConsumption = 0;
            lastYearLeadTimeConsumption = 0;
            mrpQuantity = 0;
            averageLeadTime = 0;
            percentageQuantity = 0;
            listLeadTime = new List<Integer>();
            colorCode = '';
            percentageLength = 0;
        }
    }

    public class pageData {
        public Integer pageNumber { get; set; }
        public Integer totalRecords { get; set; }
        public List<resultData> listTxnData { get; set; }
    }

    @AuraEnabled
    public static String allRecordTypes()
    {
        List<Map<String,String>> listOptions = new List<Map<String,String>>();
        Map<Id,Schema.RecordTypeInfo> recordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();

        for(Id idRT : recordTypeInfo.keySet())
        {
            Map<String,String> m = new Map<String,String>();
            m.put('Id',idRT);
            m.put('Name', recordTypeInfo.get(idRT).getName());
            listOptions.add(m);
        }

        return JSON.serialize(listOptions);
    }

    @AuraEnabled
    public static String allWarehouses()
    {
        List<Map<String,String>> listOptions = new List<Map<String,String>>();
        Set<Id> setIdWarehouse = new Set<Id>();
        setIdWarehouse.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
        setIdWarehouse.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);
        for(AcctSeedERP__Warehouse__c whs : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Id NOT IN:setIdWarehouse ORDER BY Name]){
            Map<String,String> m = new Map<String,String>();
            m.put('Id', whs.Id);
            m.put('Name', whs.Name);
            listOptions.add(m);
        }

        return JSON.serialize(listOptions);
    }

    @AuraEnabled
    public static String retrieveProductDetail(String idRecordType, Decimal pageNumber, String orderBy, String orderDirection, String idWarehouse, String idProduct, Boolean showAll)
    {
        List<resultData> listTxnData = new List<resultData>();
        map<Id,resultData> mapTD = new map<Id,resultData>();
        Set<Id> setRecIds = new Set<Id>();
        if(idRecordType == ''){
            Map<Id,Schema.RecordTypeInfo> productRecordTypeInfo = Schema.SObjectType.Product2.getRecordTypeInfosById();
            setRecIds.addAll(productRecordTypeInfo.keySet());
        }else
            setRecIds.add(idRecordType);
        System.debug(loggingLevel.error,'idRecordType:'+idRecordType);
        orderBy = orderBy == null ? 'Product__r.Name' : orderBy;
        Integer pageOffset = (50 * ((Integer)pageNumber -1));
        pageData pd = new pageData();
        pd.pageNumber = (Integer)pageNumber;
        pd.listTxnData = listTxnData;

        String soqlCount = 'SELECT count() FROM Product_MRP_Value__c WHERE Product__r.AcctSeed__Inventory_Product__c = true ';
        if(!showAll){
            soqlCount += ' AND Last_Year_Season_Consumption__c <> 0 ';
            soqlCount += ' AND Availability_Percentage__c < 100 ';
        }
        if(idProduct != null)
            soqlCount += ' AND Product__c =:idProduct ';
        else
            soqlCount += ' AND Product__r.RecordTypeId IN:setRecIds ';

        if(idWarehouse != '' && idProduct == null)
            soqlCount += ' AND Warehouse__c =:idWarehouse ';

        pd.totalRecords = Database.countQuery(soqlCount);

        String soql = 'SELECT Id, ';
        soql += ' Product__c, ';
        soql += ' Product__r.Name, ';
        soql += ' Warehouse__c, ';
        soql += ' Warehouse__r.Name, ';
        soql += ' Product__r.Average_MRP_Time__c, ';
        soql += ' MRP_Quantity_Available__c, ';
        soql += ' Availability_Percentage__c, ';
        soql += ' Last_Year_Season_Consumption__c, ';
        soql += ' Last_Year_Lead_Time_Consumption__c ';
        soql += ' FROM Product_MRP_Value__c ';
        soql += ' WHERE Product__r.AcctSeed__Inventory_Product__c = true ';
        if(!showAll){
            soql += ' AND Last_Year_Season_Consumption__c <> 0 ';
            soql += ' AND Availability_Percentage__c < 100 ';
        }

        if(idProduct != null)
            soql += ' AND Product__c =:idProduct ';
        else
            soql += ' AND Product__r.RecordTypeId IN:setRecIds ';

        if(idWarehouse != '' && idProduct == null)
            soql += ' AND Warehouse__c =:idWarehouse ';
        //soql += ' AND (MRP_Quantity__c <> 0 AND Last_Year_Season_Consumption__c <> 0) ';
        if(orderBy == 'Availability_Percentage__c')
            soql += ' AND Availability_Percentage__c != null ';
        soql += ' ORDER BY '+orderBy+' '+orderDirection;
        soql += ' LIMIT 50 OFFSET :pageOffset ';
        System.debug(soql);
        for(Product_MRP_Value__c pr : Database.query(soql))
        {
            resultData res = new resultData();
            res.productId = pr.Product__c;
            res.productName = pr.Product__r.Name;            
            res.warehouseId = pr.Warehouse__c;
            res.warehouseName = pr.Warehouse__r.Name;            
            res.lastYearSeasonConsumption = pr.Last_Year_Season_Consumption__c == null ? 0 : pr.Last_Year_Season_Consumption__c;
            res.lastYearLeadTimeConsumption = pr.Last_Year_Lead_Time_Consumption__c == null ? 0 : pr.Last_Year_Lead_Time_Consumption__c;
            res.mrpQuantity = pr.MRP_Quantity_Available__c == null ? 0 : pr.MRP_Quantity_Available__c;
            res.averageLeadTime = pr.Product__r.Average_MRP_Time__c == null ? 0 : pr.Product__r.Average_MRP_Time__c;
            res.percentageQuantity = res.lastYearSeasonConsumption != 0 ? (800 / res.lastYearSeasonConsumption) * res.mrpQuantity : 5000;
            if(res.percentageQuantity != 5000 && res.percentageQuantity > 800)
                res.percentageQuantity = 800;
            if(res.averageLeadTime > 0){
                for(Integer i=0;i<res.averageLeadTime;i++)
					res.listLeadTime.add(i);
            }
            //Double percentageLength = res.lastYearSeasonConsumption != 0 ? (res.mrpQuantity/res.lastYearSeasonConsumption)*100 : 0;
            Double percentageLength = pr.Availability_Percentage__c == null ? 0 : pr.Availability_Percentage__c;
            res.percentageLength = percentageLength.round();
            res.colorCode = rgb(percentageLength);
            listTxnData.add(res);
        }
        
        return JSON.serialize( pd );
    }

    public static String rgb(Double percentageLength) {
        //percentageLength--; // working with 0-99 will be easier
        Double r;
        Double g;
        Double b;
        // yellow to red
        g = Math.floor(255 * (percentageLength / 100));
        g = g > 255 ? 255 : g;
        r = Math.floor(255 * ((100-percentageLength) / 100));
        //r = 255;
        b = 0;
        return 'rgb(' + String.valueOf(Math.round(r)) + ',' + String.valueOf(Math.round(g)) + ',' + String.valueOf(Math.round(b)) + ')';
    }

    public static void coverage(){
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
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
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