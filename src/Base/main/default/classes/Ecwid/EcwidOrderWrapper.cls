public without sharing class EcwidOrderWrapper {
  public String id; //XJ12H
  public String subtotal; //1076.64
  public String total; //2014.97
  public String usdTotal; //2014.97
  public String tax; //488.48
  public String paymentMethod; //Credit or debit card (Mollie)
  public String paymentStatus; //PARTIALLY_REFUNDED
  public String fulfillmentStatus; //DELIVERED
  public String vendorOrderNumber; //XJ12H
  public String orderNumber; //1082727626
  public String refererUrl; //https://mdemo.ecwid.com/
  public String globalReferer; //https://my.ecwid.com/
  public String createDate; //2018-05-31 15:08:36 +0000
  public String updateDate; //2018-05-31 15:09:35 +0000
  public String createTimestamp; //1527779316
  public String updateTimestamp; //1527779375
  public boolean hidden;
  public String orderComments; //Test order comments
  public String privateAdminNotes; //Must be delivered till Sunday.
  public String email; //mscott@gmail.com
  public String ipAddress; //123.431.234.243
  public String customerId; //40201284
  public String customerGroupId; //12345
  public String customerGroup; //Gold
  public boolean customerTaxExempt;
  public String customerTaxId; //
  public boolean customerTaxIdValid;
  public boolean reversedTaxApplied;
  public String discount; //4
  public String couponDiscount; //22
  public String volumeDiscount; //4
  public String membershipBasedDiscount; //0
  public String totalAndMembershipBasedDiscount; //0
  public List<cls_customDiscount> customDiscount;
  public cls_discountCoupon discountCoupon;
  public List<cls_discountInfo> discountInfo;
  public List<cls_items> items;
  public String refundedAmount; //3.5
  public List<cls_refunds> refunds;
  public cls_Person billingPerson;
  public cls_Person shippingPerson;
  public cls_shippingOption shippingOption;
  public cls_handlingFee handlingFee;
  public List<cls_predictedPackage> predictedPackage;
  public List<cls_taxesOnShipping> taxesOnShipping;
  public String paymentModule; //CUSTOM_PAYMENT_APP-mollie-pg
  public cls_additionalInfo additionalInfo;
  public cls_paymentParams paymentParams;
  public List<cls_orderExtraFields> orderExtraFields;
  public boolean acceptMarketing;
  public String refererId; //Amazon
  public boolean disableAllCustomerNotifications;
  public boolean externalFulfillment;
  public class cls_customDiscount {
  }
  public class cls_discountCoupon {
    public String id; //29567026
    public String name; //API Testing
    public String code; //APITESTING
    public String discountType; //ABS
    public String status; //ACTIVE
    public String discount; //22
    public String launchDate; //2018-05-24 20:00:00 +0000
    public String usesLimit; //UNLIMITED
    public String applicationLimit; //NEW_CUSTOMER_ONLY
    public String creationDate; //2018-05-31 15:08:33 +0000
    public String updateDate; //2018-05-24 13:40:32 +0000
    public String orderCount; //0
  }
  public class cls_discountInfo {
    public String value; //4
    public String type; //ABS
    public String base; //ON_TOTAL
    public String orderTotal; //1
  }
  public class cls_items {
    public String id; //140273658
    public String productId; //66722487
    public String categoryId; //19563207
    public String price; //1060
    public String productPrice; //1000
    public String sku; //ABCA-IAC
    public String quantity; //1
    public String shortDescription; //
    public String tax; //331.01
    public String shipping; //0
    public String quantityInStock; //0
    public String name; //iMac
    public boolean isShippingRequired;
    public String weight; //0
    public boolean trackQuantity;
    public boolean fixedShippingRateOnly;
    public String imageUrl; //https://ecwid-images-ru.gcdn.co/images/5035009/391870914.jpg
    public String smallThumbnailUrl; //https://ecwid-images-ru.gcdn.co/images/5035009/650638292.jpg
    public String hdThumbnailUrl; //https://ecwid-images-ru.gcdn.co/images/5035009/650638293.jpg
    public String fixedShippingRate; //0
    public boolean digital;
    public boolean couponApplied;
    public List<cls_selectedOptions> selectedOptions;
    public List<cls_taxes> taxes;
    public cls_dimensions dimensions;
    public String couponAmount; //21.66
    public List<cls_discounts> discounts;
  }
  public class cls_selectedOptions {
    public String name; //Price-Optimizer
    public String value; //6
    public List<String> valuesArray;
    public List<cls_selections> selections;
    public String type; //CHOICE
  }
  public class cls_selections {
    public String selectionTitle; //6
    public String selectionModifier; //6
    public String selectionModifierType; //PERCENT
  }
  public class cls_taxes {
    public String name; //State tax
    public String value; //12
    public String total; //124.13
    public String taxOnDiscountedSubtotal; //124.13
    public String taxOnShipping; //0
    public boolean includeInPrice;
  }
  public class cls_dimensions {
    public String length; //0
    public String width; //0
    public String height; //0
  }
  public class cls_discounts {
    public cls_discountInfo discountInfo;
    public String total; //3.94
  }
  public class cls_refunds {
    public String date_x; //2017-09-12 10:12:56 +0000
    public String source; //CP
    public String reason; //Testing!
    public String amount; //3.5
  }
  public class cls_Person {
    public String name; //Michael Scott
    public String companyName; //
    public String street; //555 Lackawanna Ave
    public String city; //Scranton
    public String countryCode; //US
    public String countryName; //United States
    public String postalCode; //18508
    public String stateOrProvinceCode; //PA
    public String stateOrProvinceName; //Pennsylvania
    public String phone; //
  }
  public class cls_shippingOption {
    public String shippingCarrierName; //Shipping app the-printful
    public String shippingMethodName; //USPS Priority Mail
    public String shippingRate; //471.85
    public String estimatedTransitTime; //1-3
    public boolean isPickup;
  }
  public class cls_handlingFee {
    public String name; //Handling Fee
    public String value; //4
    public String description; //
  }
  public class cls_predictedPackage {
    public String length; //0
    public String width; //0
    public String height; //0
    public String weight; //0.4
    public String declaredValue; //1076.64
  }
  public class cls_taxesOnShipping {
    public String name; //State tax
    public String value; //12
    public String total; //57.1
  }
  public class cls_additionalInfo {
    public String google_customer_id; //2008512504.1526280224
  }
  public class cls_paymentParams {
  }
  public class cls_orderExtraFields {
    public String id; //lang
    public String value; //en
    public String customerInputType; //
    public String title; //
    public String orderDetailsDisplaySection; //
    public String orderBy; //1
  }
  public static EcwidOrderWrapper parse(String json) {
    return (EcwidOrderWrapper) System.JSON.deserialize(json.replace('"date"', '"date_x"'), EcwidOrderWrapper.class);
  }
}
