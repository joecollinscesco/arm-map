public with sharing class CescoGoogleMaps {
    @AuraEnabled(cacheable=false)
    public static Map<String, Decimal> geocode(String address) {
        if (String.isBlank(address)) {
            throw new AuraHandledException('Address is required for geocoding.');
        }

        Google_Maps_API__mdt googleApiMdt = Google_Maps_API__mdt.getInstance('Google_API_Key');
        if (googleApiMdt == null || String.isBlank(googleApiMdt.Distance_API_Key__c)) {
            throw new AuraHandledException('Google Maps API key is not configured.');
        }
        String apiKey = googleApiMdt.Distance_API_Key__c;

        String endpoint = 'https://maps.googleapis.com/maps/api/geocode/json?address='
            + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + apiKey;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse res = http.send(request);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Geocoding request failed with status ' + res.getStatusCode() + ': ' + res.getStatus());
        }

        Map<String, Object> responseMap =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        List<Object> results = (List<Object>) responseMap.get('results');

        if (results == null || results.isEmpty()) {
            return null;
        }

        Map<String, Object> first = (Map<String, Object>) results[0];
        Map<String, Object> geometry = (Map<String, Object>) first.get('geometry');
        if (geometry == null) {
            return null;
        }

        Map<String, Object> location = (Map<String, Object>) geometry.get('location');
        if (location == null) {
            return null;
        }

        return new Map<String, Decimal>{
            'lat' => Decimal.valueOf(String.valueOf(location.get('lat'))),
            'lng' => Decimal.valueOf(String.valueOf(location.get('lng')))
        };
    }
}