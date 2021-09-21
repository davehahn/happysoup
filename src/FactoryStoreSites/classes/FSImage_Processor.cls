/**
 * Created by Tim on 2021-09-20.
 */

public with sharing class FSImage_Processor {

    @AuraEnabled public Map<String, String> DefaultImages { get; set; }
    @AuraEnabled public List<MarketingImage> MarketingImages { get; set; }

    public FSImage_Processor(GMBLASERP__Serial_Number__c s){
        processImages(s);
    }

    private FSImage_Processor processImages(GMBLASERP__Serial_Number__c s){
        try
        {
            List<Legend_Gallery_Image_Map__c> imageMaps = [SELECT Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c,
                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c,
                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c,
                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c,
                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c,
                    Legend_Gallery_Image__r.Name, Legend_Gallery_Image__r.ENG_Description__c,
                    Legend_Gallery_Image__r.FR_Description__c
            FROM Legend_Gallery_Image_Map__c
            WHERE Parent_object_Id__c = :s.Id];

            if( imageMaps.size() > 0 ){
                this.MarketingImages = new List<MarketingImage>();
                for(Legend_Gallery_Image_Map__c lgim : imageMaps){
                    this.MarketingImages.add( new MarketingImage(lgim) );
                }
            }
        }
        catch(Exception e){}
        return this;
    }

    public Class MarketingImage {
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String EngDescription { get; set; }
        @AuraEnabled public String FrDescription { get; set; }
        @AuraEnabled public String AWS_Url_200_high { get; set; }
        @AuraEnabled public String AWS_Url_500x500 { get; set; }
        @AuraEnabled public String AWS_Url_700_wide { get; set; }
        @AuraEnabled public String AWS_Url_1280_wide { get; set; }
        @AuraEnabled public String AWS_Url_fullsize { get; set; }

        public MarketingImage(Legend_Gallery_Image_Map__c lgim)
        {
            this.Name = lgim.Legend_Gallery_Image__r.Name;
            this.EngDescription = lgim.Legend_Gallery_Image__r.ENG_Description__c;
            this.FrDescription = lgim.Legend_Gallery_Image__r.FR_Description__c;
            this.AWS_Url_fullsize = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c;
            this.AWS_Url_200_high = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c;
            this.AWS_Url_500x500 = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c;
            this.AWS_Url_700_wide = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c;
            this.AWS_Url_1280_wide = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c;
        }

    }
}