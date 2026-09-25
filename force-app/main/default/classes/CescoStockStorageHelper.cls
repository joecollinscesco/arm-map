/**
 * @description: Helper class for the Bill and Hold Calculator (previously called Stock Storage)
 */
public without sharing class CescoStockStorageHelper {
    @AuraEnabled(cacheable=false)
    public static Account getAccount(Id id){
       List<Account> accounts = [SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingLatitude,
               ShippingLongitude FROM Account Where Id = :id LIMIT 1];
       if(accounts.size() > 0){
         return accounts[0];
       } else{
         return null;
       }
    }
    @AuraEnabled(cacheable=false)
    public static Opportunity getOpportunity(Id id){
       return [SELECT Id, Name, AccountId, Related_Parent_Construction_Bid__c, Customer_Contact__c, Branch__c FROM Opportunity Where Id = :id LIMIT 1];
    }
    @AuraEnabled(cacheable=false)
    public static List<Contact> getContact(Id id){
      return [SELECT Id, Email, Phone, FirstName, LastName FROM Contact Where Id = :id LIMIT 1];
    }
    @AuraEnabled(cacheable=false)
    public static User getUser(Id id){
       return [SELECT Id, Name, Email, Phone From User Where Id = :id LIMIT 1];
    }
    @AuraEnabled(cacheable=false)
    public static Branch__c getBranch(Id id){
       List<Branch__c> branches = [SELECT Id, Name, Longitude__c, Latitude__c,  Racks__c,
         BranchAddress__c, BranchCity__c, BranchState__c, BranchZip__c, Cost_Per_SqFt_Monthly__c   FROM Branch__c Where Id = :id LIMIT 1];
       if(branches.size() > 0){
         return branches[0];
       } else{
         return null;
       }
    }
    @AuraEnabled(cacheable=false)
    public static Branch__c getBranchByBranchId(String branchId){
       List<Branch__c> branches = [SELECT Id, Name, Longitude__c, Latitude__c, Racks__c,
       BranchAddress__c, BranchCity__c, BranchState__c, BranchZip__c, Cost_Per_SqFt_Monthly__c  FROM Branch__c Where Branch_ID__c = :branchId LIMIT 1];
       if(branches.size() > 0){
         return branches[0];
       } else{
         return null;
       }
    }
   
    @AuraEnabled(cacheable=false)
    public static StockStorage__c getStockStorage(Id id){
      List<StockStorage__c> stockStorage = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c,
         Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
         PreparedBy__c,  SquareFootage__c, Value_of_Material_Being_Stored__c, PreparedBy__r.Name, PreparedBy__r.Email,
         Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
         Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
         Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
         Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c,Number_of_4X8_Pallets__c,
         Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
         Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c, Cost_Per_SqFt_Monthly__c, Quote_Type__c,
         Carrying_Cost__c, Distance_Between_Job_Site_and_Branch__c, Distance_Override__c, Customer_Name__c
         FROM StockStorage__c Where Id = :id LIMIT 1];
         if(stockStorage.size() > 0){
          return stockStorage[0];
        }
        return null;
    }
    @AuraEnabled(cacheable=false)
    public static StockStorage__c getStockStorageByOppId(Id oppId){
      List<StockStorage__c> stockStorage = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
         Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
         PreparedBy__c,  SquareFootage__c, Value_of_Material_Being_Stored__c, PreparedBy__r.Name, PreparedBy__r.Email,
         Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
         Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
         Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
         Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
         Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
         Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c, Cost_Per_SqFt_Monthly__c, Quote_Type__c,
         Carrying_Cost__c, Distance_Between_Job_Site_and_Branch__c, Distance_Override__c, Customer_Name__c
         FROM StockStorage__c Where StockStorage_Opportunity__c = :oppId LIMIT 1];

      if(stockStorage.size() > 0){
        return stockStorage[0];
      }
      return null;
    }
    @AuraEnabled(cacheable=false)
    public static List<StockStorage__c> getStockStorages(){
       return [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
         Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
         PreparedBy__c, Project_Staging__c, SquareFootage__c, Value_of_Material_Being_Stored__c, CreatedDate, PreparedBy__r.Name, PreparedBy__r.Email,
         Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
         Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
         Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
         Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
         Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
         Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c,Cost_Per_SqFt_Monthly__c, Quote_Type__c,
         Carrying_Cost__c, Distance_Between_Job_Site_and_Branch__c, Distance_Override__c, Customer_Name__c
         FROM StockStorage__c  LIMIT 200];
    }
    @AuraEnabled(cacheable=false)
    public static box__FRUP__c getBoxFolderIdForPCBOpportunity(Id oppId){
      List<box__FRUP__C> frups = [SELECT box__Folder_ID__c FROM box__FRUP__c WHERE box__Object_Name__c = 'Opportunity' AND box__Record_ID__c = :oppId LIMIT 1];
      if(frups.size() > 0){
        return frups[0];
      }
      return null;
    }
    @AuraEnabled
    public static StockStorage__c updateStockStorage(StockStorage__c stockStorage){
        update stockStorage;
        return stockStorage;
    }
    
    @AuraEnabled(cacheable=false)
    public static void generatePdf(String stockStorageId, String emailToSendPdfTo){
      Blob pdfBlob;
      if(!Test.isRunningTest()){
        PageReference pdfPage = new PageReference('/apex/CescoStockStoragePdf?id=' + stockStorageId);        
        pdfBlob = pdfPage.getContentAsPdf();
      }
      DateTime now = System.now();
      String ts = now.year().toString() + '-'+ now.month().toString() + '-' + now.day().toString() + '_' + now.hour().toString() + now.minute().toString() + now.second().toString();

      StockStorage__c stockStorage = CescoStockStorageHelper.getStockStorage(stockStorageId);
      Opportunity opp = [Select Id, Name, Related_Parent_Construction_Bid__c FROM Opportunity WHERE Id= :stockStorage.StockStorage_Opportunity__c LIMIT 1];
      String fileName = 'Bill&Hold_';
     
      if(stockStorage.Quote_Type__c == 'Stock'){
        fileName = 'Stock_Quote_';
        string accountName = stockStorage.Customer_Name__c;
        if(accountName != null & accountName.length() > 20){
          accountName = accountName.left(20);
        }
        fileName += accountName + '_';
      }
      if(opp.Name.length() > 50){
          fileName += opp.Name.left(50) + '_' + ts + '.pdf';
      }else{    
        fileName += opp.Name + '_' + ts + '.pdf';
      }
      fileName = fileName.replaceAll('[^a-zA-Z0-9_\\-\\&. ]', '');
      Id oppId = stockStorage.StockStorage_Opportunity__c;
      if(opp.Related_Parent_Construction_Bid__c != null){
        oppId = opp.Related_Parent_Construction_Bid__c;
      }
      if(stockStorage != null && stockStorage.StockStorage_Opportunity__c != null){
         box__FRUP__c frup = CescoStockStorageHelper.getBoxFolderIdForPCBOpportunity(oppId);      
         if(frup != null && frup.box__Folder_ID__c != null){
          System.debug('Uploading PDF to Box File ID:' + frup.box__Folder_ID__c);
          try{
            CescoCallBoxApi.uploadFile(frup.box__Folder_ID__c, pdfBlob, fileName, stockStorageId);
          }
          catch(Exception e){
              System.debug('Error encountering uploading PDF to Box folder. ' + e.getMessage());
              throw e; 
          }   
         }     
      }
    }       
     
    @AuraEnabled(cacheable=false)/**
     * Get driving distance (in meters) between two points using Google Distance Matrix API.
     * @param originAddress
     * @param destAddress
     * @return driving distance      
     */
    public static Double getDrivingDistanceByAddress(String originAddress, String destAddress) {
       if (String.isBlank(originAddress) || String.isBlank(destAddress)) {
          throw new IllegalArgumentException('Origin and destination addresses are required');
       }
       try{
            // Get API key from custom metadata
            Google_Maps_API__mdt googleApiMdt = Google_Maps_API__mdt.getInstance('Google_API_Key');
            String apiKey = googleApiMdt.Distance_API_Key__c;
            String encodedOrigin = EncodingUtil.urlEncode(originAddress, 'UTF-8');
            String encodedDestination = EncodingUtil.urlEncode(destAddress, 'UTF-8');       

            // Distance Matrix API endpoint
            String endpoint = 'https://maps.googleapis.com/maps/api/distancematrix/json'
                + '?origins=' + encodedOrigin
                + '&destinations=' + encodedDestination
                + '&mode=driving'
                + '&units=imperial'
                + '&key=' + apiKey;

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');

            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() != 200) {
              System.debug('Google Distance Matrix API error: ' + response.getStatusCode());
              System.debug('Google Distance Matrix API error: ' + response.getBody());
              throw new CalloutException('Google Maps Distance API Error: ' 
                    + response.getStatusCode() + ' - ' + response.getBody());
            }

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String jsonPretty = JSON.serializePretty(root);
            System.debug('Google Maps Distance Response: ' + jsonPretty);

            // Navigate into rows → elements → distance → text
            List<Object> rows = (List<Object>) root.get('rows');
            if (rows.isEmpty()) {
                throw new CalloutException('No data returned from Google Maps API Distance Callout');
            }

            Map<String, Object> firstRow = (Map<String, Object>) rows[0];
            List<Object> elements = (List<Object>) firstRow.get('elements');
            Map<String, Object> firstElement = (Map<String, Object>) elements[0];
            Map<String, Object> distance = (Map<String, Object>) firstElement.get('distance');
            if (distance == null) {
              throw new CalloutException('Distance data not available in API response');
            }
            // Extract the text field (e.g., "7.7 mi")
            String distanceText = (String) distance.get('text');
            if (String.isBlank(distanceText)) {
               throw new CalloutException('Distance text not found in API response');
            }
            // Remove the " mi" suffix
            String milesOnly = distanceText.replace(' mi', '').replace(',','');
            // Convert to Double
            Double distanceMiles = Double.valueOf(milesOnly);
            return distanceMiles;
          }
          catch (CalloutException e) {
             throw e; // Re-throw callout exceptions
          } 
          catch (Exception e) {
              System.debug(LoggingLevel.ERROR, 'Unexpected error in getDrivingDistanceByAddress: ' + e.getMessage());
              throw new CalloutException('Error calculating distance: ' + e.getMessage());
          }
    }
}