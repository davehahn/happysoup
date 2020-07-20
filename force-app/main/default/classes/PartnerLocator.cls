/**
 * Created by dave on 2019-10-31.
 */

public without sharing class PartnerLocator
{
  public class PartnerLocator_Exception extends Exception{}

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

    public AccountWrapper(Account acct)
    {
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
      this.description = buildDescription( acct );
    }

    public Integer compareTo( Object compareTo )
    {
      AccountWrapper compareAW = (AccountWrapper)compareTo;
      if( distance == compareAW.distance ) return 0;
      if( distance > compareAW.distance ) return 1;
      return -1;
    }

    private String buildDescription( Account acct )
    {
      String result = acct.BillingStreet;
      result += '<br />' + acct.BillingCity + ', ' + acct.BillingState;
      result += '<br />' + acct.BillingPostalCode;
      result += '<br />' + acct.Phone;
      if( acct.AccountEmail__c != null )
      {
        result += '<div style="margin-top:0.5rem">' + acct.AccountEmail__c + '</div>';
      }
      return result;
    }

  }

  public class MapMarker {
    public String id;
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

    public MapMarker( AccountWrapper wrapper )
    {
      this.location = new Map<String, String>{
        'Latitude' => String.valueOf( wrapper.latitude ),
        'Longitude' => String.valueOf( wrapper.longitude ),
        'City' => wrapper.city,
        'PostalCode' => wrapper.postalCode,
        'State' => wrapper.prov,
        'Country' => wrapper.country,
        'Street' => wrapper.street
      };
      this.id = wrapper.id;
      this.title = wrapper.name + ' ( ' + wrapper.distance_text + ' )';
      this.icon = 'standard:account';
      this.description = wrapper.description;
      this.distance = wrapper.distance_text;
      this.duration = wrapper.duration_text;
      this.name = wrapper.name;
      this.phone = wrapper.phone;
      this.email = wrapper.email;
      this.website = wrapper.website;
    }
  }

  public class SearchResult {
    public String origin_address;
    public List<MapMarker> mapMarkers;
    public SearchResult(){}
  }

  public String origin;
  public String destinations;
  public List<String> excludeAccountIds;
  public Integer resultSize;
  private Map<String, AccountWrapper> accountMap;
  private List<Account> partners;

  public PartnerLocator()
  {
    this.excludeAccountIds = new List<String>{
      Legend_Settings__c.getOrgDefaults().LegendWholesaleAccountId__c
    };
  }

  public void exclude( String excludeAccountIds )
  {
    this.excludeAccountIds.addAll( excludeAccountIds.split(',') );
  }

  public SearchResult execute( String origin, Integer resultSize )
  {
    this.origin = origin;
    this.resultSize = resultSize == null ? 1 : resultSize;
    setDestinations();
    return processResult( doGoogleCallout() );
  }

  private void setDestinations()
  {
    this.accountMap = makeAccountMap();
    String destinations = '';
    for( String d : this.accountMap.keySet() )
    {
      destinations += d + '|';
    }
    this.destinations = destinations.removeEnd('|');
  }

  private Map<String, AccountWrapper> makeAccountMap()
  {
    if( this.partners == null )
    {
      fetchPartners();
    }
    Map<String, AccountWrapper> result = new Map<String,AccountWrapper>();

    for( Account a : this.partners )
    {
      if( !this.excludeAccountIds.contains( a.Id ) )
      {
        result.put(String.valueOf(a.BillingLatitude) + ',' + String.valueOf(a.BillingLongitude), new AccountWrapper(a));
      }
    }
    return result;
  }

  private void fetchPartners()
  {
    this.partners = [SELECT Id,
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
                            BillingLatitude
                      FROM Account
                      WHERE RecordType.Name = 'Dealer'
                      AND Active__c = true
                      AND BillingLongitude <> null
                      AND BillingLatitude <> null ];
  }

  private GoogleAPI.GoogleDestinationsResult doGoogleCallout()
  {
    GoogleAPI.DistanceMatrix gDistanceMatrix = new GoogleAPI.DistanceMatrix( this.origin, this.destinations );
    GoogleAPI.GoogleDestinationsResult gdResult = gDistanceMatrix.execute();
    if( gdResult.status != 'OK' ||
      gdResult.origin_addresses.size() == 0 ||
      gdResult.rows[0].elements[0].status == 'NOT_FOUND' )
    {
      throw new PartnerLocator_Exception( origin + ' does not appear to be valid');
    }
    return gdResult;
  }

  private SearchResult processResult( GoogleAPI.GoogleDestinationsResult gdResult )
  {
    SearchResult result = new SearchResult();
    result.origin_address = gdResult.origin_addresses[0];
    for( Integer i=0; i<this.accountMap.keySet().size(); i++ )
    {
      if( gdResult.rows[0].elements[i].status == 'OK')
      {
        accountMap.values()[i].distance = Decimal.valueOf( gdResult.rows[0].elements[i].distance.get('value') );
        accountMap.values()[i].distance_text = gdResult.rows[0].elements[i].distance.get('text');
        accountMap.values()[i].duration_text = gdResult.rows[0].elements[i].duration.get('text');
      }
    }
    List<AccountWrapper> sortedAccounts = accountMap.values();
    sortedAccounts.sort();
    result.mapMarkers = new List<MapMarker>();
    for( Integer i=0; i<sortedAccounts.size(); i++ )
    {
      if( i >= this.resultSize )
        break;
      result.mapMarkers.add( new MapMarker( sortedAccounts[i] ) );
    }
    return result;
  }

}