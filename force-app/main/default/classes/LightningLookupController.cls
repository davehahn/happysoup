public class LightningLookupController {

    /*
     * Loads the initial value of the given SObject type with ID "value"
     */
    @AuraEnabled
    public static String getCurrentValue(String type, String value){
        if(String.isBlank(type)){
            return null;
        }

        ID lookupId = null;
        try{
            lookupId = (ID)value;
        }catch(Exception e){
            return null;
        }

        if(String.isBlank(lookupId)){
            return null;
        }

        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null){
            return null;
        }

        String nameField = getSobjectNameField(objType);
        String query = 'Select Id, '+nameField+' From '+type+' Where Id = \''+lookupId+'\'';
        List<SObject> oList = Database.query(query);
        if(oList.size()==0) {
            return null;
        }
        return (String) oList[0].get(nameField);
    }

    /*
     * Utility class for search results
    */
    public class SearchResult{
        public String value{get;Set;}
        public String id{get;set;}
        public String secondary{get;Set;}
    }

    /*
     * Returns the "Name" field for a given SObject (e.g. Case has CaseNumber, Account has Name)
    */
    private static String getSobjectNameField(SobjectType sobjType){

        //describes lookup obj and gets its name field
        String nameField = 'Name';
        Schema.DescribeSObjectResult dfrLkp = sobjType.getDescribe();
        for(schema.SObjectField sotype : dfrLkp.fields.getMap().values()){
            Schema.DescribeFieldResult fieldDescObj = sotype.getDescribe();
            if(fieldDescObj.isNameField() ){
                nameField = fieldDescObj.getName();
                break;
            }
        }
        return nameField;
    }

    /*
     * Searchs (using SOSL) for a given Sobject type
     */
    @AuraEnabled
    public static String searchSObject(String type, String searchString, String serializedFilters, String pricebookId, String secondaryField){
        if(String.isBlank(type) || String.isBlank(searchString)){
            return null;
        }

        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null){
            return null;
        }

        if (type != 'Product2' && !String.isBlank(pricebookId)) {
            // only product2 can have pricebooks
            return null;
        }

        String nameField = getSobjectNameField(objType);
        searchString = '\'*'+searchString+'*\'';

        // parse filters
        String whereString = '';
        if (!String.isBlank(serializedFilters)) {
            List<Map<String,String>> filters =
              (List<Map<String,String>>)JSON.deserialize(serializedFilters, List<Map<String,String>>.class);
            for (Integer i=0; i<filters.size(); i++) {
                Map<String,String> filter = filters[i];
                if (!filter.containsKey('field') || !filter.containsKey('comparator') || !filter.containsKey('value')) {
                    // this filter is missing info, so skip the search
                    return null;
                }
                if (whereString.length() > 0) {
                    whereString += ' AND ';
                }
                whereString += filter.get('field') + ' ' + filter.get('comparator') + ' \'' + filter.get('value') + '\'';
            }
            if (whereString.length() > 0) {
                whereString = ' WHERE ' + whereString;
            }
        }

        // use pricebook if provided
        String withPricebook = '';
        if (!String.isBlank(pricebookId)) {
            withPricebook = ' WITH PricebookId = \'' + pricebookId + '\'';
        }

        String fields = nameField;

        if (secondaryField != null && secondaryField != '') {
            fields += ', ' + secondaryField;
        }

        String soslQuery = 'FIND ' + searchString + ' IN NAME FIELDS RETURNING '
                          + type +'(Id, '+fields+whereString+' ORDER BY '+nameField+')'+withPricebook+' LIMIT 20';
        List<List<SObject>> results =  Search.query(soslQuery);

        List<SearchResult> output = new List<SearchResult>();
        if(results.size()>0){
            for(SObject sobj : results[0]){
                SearchResult sr = new SearchResult();
                sr.id = (String)sobj.get('Id');
                sr.value = (String)sobj.get(nameField);
                if (secondaryField != null && secondaryField != '') {
                    sr.secondary = (String)sobj.get(secondaryField);
                }
                output.add(sr)   ;
            }
        }
        return JSON.serialize(output);
    }

    @AuraEnabled
    public static String getSObjectLabel(String type) {
        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null){
            return null;
        }
        return objType.getDescribe().getLabel();
    }
}