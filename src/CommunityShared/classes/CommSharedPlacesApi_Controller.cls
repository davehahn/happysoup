/**
 * Created by Tim on 2021-05-12.
 */

public with sharing class CommSharedPlacesApi_Controller {
  @AuraEnabled(cacheable=true)
  public static GoogleApi.GooglePlacesDetailsResult fetchPlacesApiResult(
    String input,
    String inputType,
    String fields
  ) {
    GoogleAPI.PlacesMatrix gPlacesMatrix = new GoogleAPI.PlacesMatrix(input, inputType, fields);
    GoogleAPI.GooglePlacesSearch gpSearch = gPlacesMatrix.execute();
    //        System.debug('TIM gpSearch: ' + gpSearch);
    //        System.debug('place_id: ' + gpSearch.candidates[0].place_id);

    GoogleAPI.PlacesDetailsMatrix gPlacesDetailsMatrix = new GoogleAPI.PlacesDetailsMatrix(
      gpSearch.candidates[0].place_id
    );
    GoogleAPI.GooglePlacesDetails gpResult = gPlacesDetailsMatrix.execute();

    GoogleApi.GooglePlacesDetailsResult details = gpResult.result;
    //System.debug('Tim Place Details: ' + details);
    return details;
  }

  @AuraEnabled(Cacheable=true)
  public static GoogleAPI.GoogleDestinationsResult fetchDistanceApiResult(String origin, String destinations) {
    System.debug('in fetchDistanceApiResult');
    System.debug('my origins: ' + origin);
    System.debug('my destinations: ' + destinations);
    GoogleAPI.DistanceMatrix gDistanceMatrix = new GoogleAPI.DistanceMatrix(origin, destinations);
    GoogleAPI.GoogleDestinationsResult gdResult = gDistanceMatrix.execute();
    return gdResult;
  }
}
