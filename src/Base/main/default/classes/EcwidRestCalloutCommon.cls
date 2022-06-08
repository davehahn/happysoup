public class EcwidRestCalloutCommon {
    
    public class RestObjct{
     
        String id {get;set;}
        String subtotal {get;set;}
        String total {get;set;}
        String usdTotal {get;set;}
        String tax {get;set;}
        String paymentMethod {get;set;}
        String paymentStatus {get;set;}
        String fulfillmentStatus {get;set;}
        String vendorOrderNumber {get;set;}
        String orderNumber {get;set;}
        
        String createDate {get;set;}
        String updateDate {get;set;}
        String orderComments {get;set;}
        String privateAdminNotes {get;set;}
        String email {get;set;}
        String customerId {get;set;}
        String customerGroupId {get;set;}
        String customerGroup {get;set;}
        String customerTaxExempt {get;set;}
        String customerTaxId {get;set;}
        
    }
    
    public class ecwidOrderItem{
        String id {get;set;}
        String productId {get;set;}
        String categoryId {get;set;}
        String price {get;set;}
        String productPrice {get;set;}
        String sku {get;set;}
        String quantity {get;set;}
        String shortDescription {get;set;}
        String tax {get;set;}
        String shipping {get;set;}
        String quantityInStock {get;set;}
        String name {get;set;}
        String isShippingRequired {get;set;}
        String weight {get;set;}
        String trackQuantity {get;set;}
        String fixedShippingRateOnly {get;set;}
        String couponApplied {get;set;}
    }
    public class ecwidOrderItemTax{
        String name {get;set;}
        String value {get;set;}	
        String total {get;set;}
        String taxOnDiscountedSubtotal {get;set;}
        String taxOnShipping {get;set;}
        String includeInPrice {get;set;}
    }

}