/**
 * Created by dave on 2019-10-31.
 */

public without sharing class PartnerLocator {
  public class PartnerLocator_Exception extends Exception {
  }

  public class AccountWrapper implements Comparable {
    public String id;
    public String email;
    public String website;
    public String phone;
    public String country;
    public String street;
    public String city;
    public String prov;
    public String postalCode;
    public String description;
    public Decimal distance;
    public String distance_text;
    public String duration_text;
    public String name;
    public Decimal longitude;
    public Decimal latitude;
    public Boolean isFactoryStore;

    public AccountWrapper(Account acct) {
      this.id = acct.Id;
      this.name = acct.Name;
      this.email = acct.AccountEmail__c;
      this.website = acct.Website;
      this.phone = acct.Phone;
      this.country = acct.BillingCountry;
      this.longitude = acct.BillingLongitude;
      this.latitude = acct.BillingLatitude;
      this.street = acct.BillingStreet;
      this.city = acct.BillingCity;
      this.prov = acct.BillingState;
      this.postalCode = acct.BillingPostalCode;
      this.isFactoryStore = acct.Is_Internal__c;
      this.description = buildDescription(acct);
    }

    public Integer compareTo(Object compareTo) {
      AccountWrapper compareAW = (AccountWrapper) compareTo;
      if (distance == compareAW.distance)
        return 0;
      if (distance > compareAW.distance)
        return 1;
      return -1;
    }

    private String buildDescription(Account acct) {
      String result = acct.BillingStreet;
      result += '<br />' + acct.BillingCity + ', ' + acct.BillingState;
      result += '<br />' + acct.BillingPostalCode;
      result += '<br />' + acct.Phone;
      if (acct.AccountEmail__c != null) {
        result += '<br />' + acct.AccountEmail__c;
      }
      return result;
    }
  }

  public class MapMarker {
    public String id;
    public String value;
    public Map<String, String> location;
    public String title;
    public String icon;
    public String description;
    public String name;
    public String phone;
    public String email;
    public String website;
    public String distance;
    public String duration;
    public Map<String, Object> mapIcon;

    public MapMarker(AccountWrapper wrapper) {
      this.location = new Map<String, String>{
        'Latitude' => String.valueOf(wrapper.latitude),
        'Longitude' => String.valueOf(wrapper.longitude),
        'City' => wrapper.city,
        'PostalCode' => wrapper.postalCode,
        'State' => wrapper.prov,
        'Country' => wrapper.country,
        'Street' => wrapper.street
      };
      this.id = wrapper.id;
      this.value = wrapper.id;
      this.title = wrapper.name + ' ( ' + wrapper.distance_text + ' )';
      this.icon = wrapper.isFactoryStore ? 'standard:goals' : 'standard:delegated_account';
      this.description = wrapper.description;
      this.distance = wrapper.distance_text;
      this.duration = wrapper.duration_text;
      this.name = wrapper.name;
      this.phone = wrapper.phone;
      this.email = wrapper.email;
      this.website = wrapper.website;
      this.mapIcon = wrapper.isFactoryStore
        ? standardMapMarker('#57AADF')
        : standardMapMarker('#06834C');
    }

    private Map<String, Object> standardMapMarker(String color) {
      return new Map<String, Object>{
        'fillColor' => color,
        'path' => 'M 256,480c-84.828,0-153.6-68.157-153.6-152.228c0-84.081, 153.6-359.782, 153.6-359.782s 153.6,275.702, 153.6,359.782C 409.6,411.843, 340.828,480, 256,480z M 255.498,282.245c-26.184,0-47.401,21.043-47.401,46.981c0,25.958, 21.217,46.991, 47.401,46.991c 26.204,0, 47.421-21.033, 47.421-46.991 C 302.92,303.288, 281.702,282.245, 255.498,282.245z',
        'fillOpacity' => 1,
        'strokeWeight' => 0,
        'strokeOpacity' => 0,
        'scale' => 0.1,
        'anchor' => new Map<String, Object>{ 'x' => 255.498, 'y' => -26.204 },
        'rotation' => 180
      };
    }

    private Map<String, Object> storeMapMarker() {
      return new Map<String, Object>{
        'path' => 'M33.48,16.74c0,12.19-14.16,26.49-14.76,27.1a2.81,2.81,0,0,1-3.95,0C14.17,43.23,0,28.93,0,16.74a16.74,16.74,0,0,1,33.48,0ZM19,7.5m9.6,11.43a1.91,1.91,0,0,0-.58-.77c-1.63-1.31-5.24-.16-5.24-.16a34.9,34.9,0,0,0-5.57,2.12c-2.17,1-4.28,2.07-6.3,2.33a5.52,5.52,0,0,1-.71.05,5.28,5.28,0,0,1-2.27-.44,5.59,5.59,0,0,1-.6-.3,3.27,3.27,0,0,1-1.17-1.47,10.49,10.49,0,0,1-.62-3.56A11,11,0,0,1,15.54,6L7.63,18.37a1.43,1.43,0,0,0,.78,2.25,5.71,5.71,0,0,0,.72.22A5,5,0,0,0,9.9,21a8.75,8.75,0,0,0,2.78-.1,6,6,0,0,0,.64-.15h0a11.55,11.55,0,0,0,1.74-.6l.46-.2,1.6-.73a36,36,0,0,1,5.56-2.13,11.81,11.81,0,0,1,1.81-.38,19.9,19.9,0,0,1,2.7-.24h2A12.29,12.29,0,0,0,16.74,4.7a12.27,12.27,0,0,0-12.51,12,12.27,12.27,0,0,0,12.51,12A12.49,12.49,0,0,0,28.5,20.85a2.64,2.64,0,0,0,.05-1.92Zm-9.61-7,3-4.82a10.86,10.86,0,0,1,5.81,7.45H17.31Zm4.88,13.19-.28.21h0a11.54,11.54,0,0,1-6.79,2.19,11.35,11.35,0,0,1-9.4-4.88,6.36,6.36,0,0,0,3.54,1.12,7.38,7.38,0,0,0,.82,0l.59-.1c3.5-.65,7.34-2.78,9.79-2.76h.08a3.33,3.33,0,0,1,2.29.91s1.63,1.53-.63,3.34Z',
        'fillColor' => '#00b0ed',
        'fillOpacity' => 1,
        'strokeWeight' => 1,
        'strokeOpacity' => 0,
        'scale' => 1,
        'anchor' => new Map<String, Object>{ 'x' => 16.83, 'y' => 44.7 }
      };
    }
  }

  public class SearchResult {
    public String origin_address;
    public List<MapMarker> mapMarkers;
    public SearchResult() {
    }
  }

  public String origin;
  public String destinations;
  public List<String> excludeAccountIds;
  public Integer resultSize;
  private Map<String, AccountWrapper> accountMap;
  private List<Account> partners;

  public PartnerLocator() {
    this.excludeAccountIds = new List<String>{
      Legend_Settings__c.getOrgDefaults().LegendWholesaleAccountId__c
    };
  }

  public void exclude(String excludeAccountIds) {
    this.excludeAccountIds.addAll(excludeAccountIds.split(','));
  }

  public SearchResult execute(String origin, Integer resultSize) {
    this.origin = origin;
    this.resultSize = resultSize == null ? 1 : resultSize;
    setDestinations();
    return processResult(doGoogleCallout());
  }

  private void setDestinations() {
    this.accountMap = makeAccountMap();
    String destinations = '';
    for (String d : this.accountMap.keySet()) {
      destinations += d + '|';
    }
    this.destinations = destinations.removeEnd('|');
  }

  private Map<String, AccountWrapper> makeAccountMap() {
    if (this.partners == null) {
      fetchPartners();
    }
    Map<String, AccountWrapper> result = new Map<String, AccountWrapper>();

    for (Account a : this.partners) {
      if (!this.excludeAccountIds.contains(a.Id)) {
        result.put(
          String.valueOf(a.BillingLatitude) +
          ',' +
          String.valueOf(a.BillingLongitude),
          new AccountWrapper(a)
        );
      }
    }
    return result;
  }

  private void fetchPartners() {
    this.partners = [
      SELECT
        Id,
        Name,
        Phone,
        AccountEmail__c,
        Website,
        BillingCity,
        BillingStreet,
        BillingCountry,
        BillingPostalCode,
        BillingState,
        BillingLongitude,
        BillingLatitude,
        Is_Internal__c
      FROM Account
      WHERE
        RecordType.Name = 'Dealer'
        AND Active__c = TRUE
        AND BillingLongitude != NULL
        AND BillingLatitude != NULL
    ];
  }

  private GoogleAPI.GoogleDestinationsResult doGoogleCallout() {
    GoogleAPI.DistanceMatrix gDistanceMatrix = new GoogleAPI.DistanceMatrix(
      this.origin,
      this.destinations
    );
    GoogleAPI.GoogleDestinationsResult gdResult = gDistanceMatrix.execute();
    if (
      gdResult.status != 'OK' ||
      gdResult.origin_addresses.size() == 0 ||
      gdResult.rows[0].elements[0].status == 'NOT_FOUND'
    ) {
      throw new PartnerLocator_Exception(
        origin + ' does not appear to be valid'
      );
    }
    return gdResult;
  }

  private SearchResult processResult(
    GoogleAPI.GoogleDestinationsResult gdResult
  ) {
    SearchResult result = new SearchResult();
    result.origin_address = gdResult.origin_addresses[0];
    for (Integer i = 0; i < this.accountMap.keySet().size(); i++) {
      if (gdResult.rows[0].elements[i].status == 'OK') {
        accountMap.values()[i].distance = Decimal.valueOf(
          gdResult.rows[0].elements[i].distance.get('value')
        );
        accountMap.values()[i].distance_text = gdResult.rows[0]
          .elements[i]
          .distance.get('text');
        accountMap.values()[i].duration_text = gdResult.rows[0]
          .elements[i]
          .duration.get('text');
      }
    }
    List<AccountWrapper> sortedAccounts = accountMap.values();
    sortedAccounts.sort();
    result.mapMarkers = new List<MapMarker>();
    for (Integer i = 0; i < sortedAccounts.size(); i++) {
      if (i >= this.resultSize)
        break;
      result.mapMarkers.add(new MapMarker(sortedAccounts[i]));
    }
    return result;
  }
}
