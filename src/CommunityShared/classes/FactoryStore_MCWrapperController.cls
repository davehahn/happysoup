/**
 * Created by Tim on 2021-04-26.
 */

public with sharing class FactoryStore_MCWrapperController {

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.ManagedContentVersion> initMethod(String contentType){
        MCController mcController = new MCController(contentType);
        return mcController.results;
    }

    public class MCController{
        @AuraEnabled public String managedContentIdsStr { get; set; }
        @AuraEnabled public String topicNamesStr { get; set; }
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String communityId { get; set; }
        @AuraEnabled public List<ConnectApi.ManagedContentVersion> results { get; set; }

        public MCController(String contentType){
            communityId = Network.getNetworkId();
            getMCContent(contentType);
        }

        public void getMCContent(String contentType) {
            List<String> contentIds = new List<String>();
            List<String> topicNames = new List<String>();

            try{
                if(topicNamesStr != null && !String.isEmpty(topicNamesStr)){
                    topicNames = topicNamesStr.split(',', -1);
                }

                for(Integer i=0; i<topicNames.size(); i++){
                    topicNames.set(i, topicNames.get(i).trim());
                }

                String language = 'en_US';
                System.debug('contentType: ' + contentType);
                ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByTopicsAndIds(communityId, contentIds, topicNames, 0, 25, language, contentType);
                results = contentList.items;
            }
            catch(ConnectApi.ConnectApiException e){
                errorMessage = e.getMessage();
                System.debug('Error Message: ' + e);
                ApexPages.addMessages(e);
                results = new List<ConnectApi.ManagedContentVersion>();
            }
        }
    }

//    @AuraEnabled(cacheable=true)
//    public static List<ConnectApi.ManagedContentVersion> initMethod(){
//        MCController mcController = new MCController();
//        return mcController.results;
//    }
//
//    public class MCController{
//        @AuraEnabled public String managedContentIdsStr { get; set; }
//        @AuraEnabled public String topicNamesStr { get; set; }
//        @AuraEnabled public String contentType { get; set; }
//        @AuraEnabled public String errorMessage { get; set; }
//        @AuraEnabled public String communityId {get; set; }
//        @AuraEnabled public List<ConnectApi.ManagedContentVersion> results { get; set; }
//
//        public MCController(){
//            communityId = Network.getNetworkId();
//            getMContent();
//        }
//
//        public void getMContent() {
//            List<String> contentIds = new List<String>();
//            List<String> topicNames = new List<String>();
//            try{
//                if(topicNamesStr != null && !String.isEmpty(topicNamesStr)){
//                    topicNames = topicNamesStr.split(',',-1);
//                }
//
//
//                for(Integer i=0;i<topicNames.size();i++){
//                    topicNames.set(i,topicNames.get(i).trim());
//                }
//
//                String language = 'en_US';
//                //Note: "news" is the contenttype of the content value hard coded in the code here.
//                ConnectApi.ManagedContentVersionCollection contentList = ConnectApi.ManagedContent.getManagedContentByTopicsAndIds(communityId, contentIds, topicNames, 0, 25, language, 'Legend_Deals');
//                results = contentList.items;
//            }
//            catch(ConnectApi.ConnectApiException e){
//                errorMessage = e.getMessage();
//                System.debug('Error Message : '+e);
//                ApexPages.addMessages(e);
//                results = new List<ConnectApi.ManagedContentVersion>();
//            }
//        }
//    }
}