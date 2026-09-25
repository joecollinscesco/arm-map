@isTest
private class CescoStockStorageHelperTests {
    static Id pcbOppRecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Parent Construction Bid').getRecordTypeId();
    static Profile saProfile = [SELECT Id,Name FROM Profile WHERE Name=:'System Administrator' LIMIT 1];
    static Profile salesProfile = [SELECT Id,Name FROM Profile WHERE Name=:'Sales' LIMIT 1];
    @TestSetup
    static void makeData(){  
        // Set mock callout
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            Branch__c branch = new Branch__c(Name='B054', Branch_ID__c = 'B054', BranchAddress__c = '205 MOORE LN', Latitude__c = '45.765905', Longitude__c = '-108.542182',
             BranchCity__c = 'Billings', BranchZip__c = '59101-3418', BranchState__c = 'MT', Cost_Per_SqFt_Monthly__c = 1.2, Racks__c = 3);
            insert branch;
            //Box Setup
            Box_Folders_Config__c bfcTemplate = new Box_Folders_Config__c(Name = 'PCB Template', Box_Folder_Id__c = '12345',  Page_Folder_Used_For__c = 'PCB');
            insert bfcTemplate;
    
            Box_Folders_Config__c bfc = new Box_Folders_Config__c();
            bfc.Branch__c = 'B054';
            bfc.Super_District__c = 'SDBIGSKY';
            bfc.Name = 'MT';
            bfc.Box_Folder_Id__c = '12345';
            bfc.Page_Folder_Used_For__c = 'PCB';
            insert bfc;
    
            //Test.setMock(HttpCalloutMock.class, new CescoBoxApiCalloutMockStatus200());  
    
            Account pcbAccount = new Account(name='*Project*', Super_District__c = 'SDBIGSKY', Branch__c = 'B054');
            insert pcbAccount;
    
            Account bidAccount = new Account(name='bidAccount', Super_District__c = 'SDBIGSKY', Branch__c = 'B054');
            insert bidAccount;
    
            Contact contact = new Contact(FirstName = 'Terry', LastName ='Test', Phone = '5555555555', email = 'terry@test.com', AccountId = bidAccount.Id);
            insert contact;
    
            Id pricebookId = Test.getStandardPricebookId();
            Opportunity oppPcb = new Opportunity();
            oppPcb.RecordTypeId = pcbOppRecordTypeId;
            oppPcb.Name = 'Test PCB Opp';
            oppPcb.CloseDate = Date.valueOf(System.now() + 10);
            oppPcb.StageName = 'RFP/RFQ';
            oppPcb.AccountId = pcbAccount.Id;
            oppPcb.Super_District__c = 'SDBIGSKY';
            oppPcb.Branch__C = 'B054';
            oppPcb.Pricebook2Id = pricebookId;    
            oppPcb.Project_Code__c = 'Single Family Housing';
            insert oppPcb;
        } catch(Exception e){
            System.debug('Error: ' + e.getMessage());
            throw(e);
        }
    }   

    @isTest
    static void getAccount_TestFieldsReturned() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

         Account existingAcc = new Account(Name = 'Test Account',
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City', 
            ShippingState = 'Test State',
            ShippingCountry = 'USA',
            ShippingPostalCode = '95336', ShippingLatitude = 30.325970123,
            ShippingLongitude = -81.656761, Super_District__c = 'SDBIGSKY', Branch__c = 'B054');
        Insert existingAcc;

        Account acc = CescoStockStorageHelper.getAccount(existingAcc.Id);

        Assert.isTrue(acc.Name == 'Test Account');
        Assert.isTrue(acc.ShippingStreet == 'Test Street');
        Assert.isTrue(acc.ShippingCity == 'Test City');
        Assert.isTrue(acc.ShippingState == 'Test State');
        Assert.isTrue(acc.ShippingCountry == 'USA');
        Assert.isTrue(acc.ShippingPostalCode == '95336');
        Assert.isTrue(acc.ShippingLatitude == 30.325970123);
        Assert.isTrue(acc.ShippingLongitude == -81.656761);
    }
    @isTest
    static void getAccount_TestNotFound(){
        Account acc = CescoStockStorageHelper.getAccount('0016S00003NmoDFQAZ');

        Assert.isTrue(acc == null);
    }
    @isTest
    static void getOpportunity_TestFieldsReturned() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact contact = [SELECT Id From Contact Where Email = 'terry@test.com'];
        Account pcbAccount = [SELECT Id From Account Where Name = '*Project*'];
        Account bidAccount = [SELECT Id From Account Where Name = 'bidAccount'];
        Branch__c branch = [SELECT Id From Branch__c Where Name='B054'];       
        Opportunity pcbOpp = [SELECT Id From Opportunity Where Name='Test PCB Opp' LIMIT 1];
        Opportunity existingOpp = new Opportunity(Name = 'Test Opportunity', AccountId= bidAccount.Id, StageName = 'RFP/RFQ', CloseDate = Date.valueOf(System.now() + 10),
          Related_Parent_Construction_Bid__c = pcbOpp.Id,Customer_Contact__c = contact.Id, Super_District__c = 'SDBIGSKY', Branch__c = 'B054');
        insert existingOpp;

        Opportunity opp = CescoStockStorageHelper.getOpportunity(existingOpp.Id);

        Assert.isTrue(opp.Name.startsWith('Test PCB'));
        Assert.isTrue(opp.AccountId == bidAccount.Id);
        Assert.isTrue(opp.Related_Parent_Construction_Bid__c == pcbOpp.Id);
        Assert.isTrue(opp.Customer_Contact__c == contact.Id);
        Assert.isTrue(opp.Branch__c == 'B054');
    }
    @isTest
    static void getContact_TestFieldsReturned(){
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact contact = [SELECT Id From Contact Where Email = 'terry@test.com'];
        List<Contact> contacts = CescoStockStorageHelper.getContact(contact.Id);
        Assert.isTrue(contacts[0].FirstName == 'Terry');
        Assert.isTrue(contacts[0].LastName == 'Test');
        Assert.isTrue(contacts[0].Phone == '5555555555');
        Assert.isTrue(contacts[0].Email == 'terry@test.com');
    }
    @isTest 
    static void getUser_TestFieldsReturned(){
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        User testuser1 = new User(Alias = 'stadt1', Email='standarduser2@testorg.com',EmailEncodingKey='UTF-8',LastName='Testing', FirstName = 'Tina',
        LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = saProfile.Id,TimeZoneSidKey='America/Los_Angeles',
         UserName='standarduser1'+Math.random()+'@testorg.com', Phone='9998887751');
        INSERT testUser1;
        User existingUser = [SELECT Id FROM User WHERE Email = 'standarduser2@testorg.com' LIMIT 1];
        User user = CescoStockStorageHelper.getUser(existingUser.Id);
        Assert.isTrue(user.Name == 'Tina Testing');
        Assert.isTrue(user.Email == 'standarduser2@testorg.com');
        Assert.isTrue(user.Phone == '9998887751');
    }
   
    

    @isTest 
    static void getDrivingDistanceByAddress_TestEmptyRows_Throws() {
        // Arrange mock where rows is empty
        Test.setMock(HttpCalloutMock.class, new CescoMockGoogleMapsDistanceMatrixResponseEmptyRows());
        String startAddress = '5505 PATTERSON AVE SE STE 100, KENTWOOD, MI, 49512';
        String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';

        // Act + Assert
        Boolean threw = false;
        try {
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        } catch (Exception e) {
            threw = true;
            System.assert(e.getMessage().contains('No data returned from Google Maps API Distance Callout'), 'Should throw for empty rows');
        }
        System.assertEquals(true, threw, 'Expected exception to be thrown when rows are empty');
    }
    @isTest 
    static void getBranch_TestFieldsReturned(){   
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Branch__c existingBranch = [SELECT  Id FROM Branch__c Where Name='B054' LIMIT 1];
        Branch__c branch = CescoStockStorageHelper.getBranch(existingBranch.Id);
        Assert.isTrue(branch.Cost_Per_SqFt_Monthly__c == 1.2);
        Assert.isTrue(branch.BranchAddress__c == '205 MOORE LN');
        Assert.isTrue(branch.BranchCity__c == 'Billings');
        Assert.isTrue(branch.BranchState__c == 'MT');
        Assert.isTrue(branch.BranchZip__c == '59101-3418');
        Assert.isTrue(branch.Racks__c == 3);
        Assert.isTrue(branch.Longitude__c == '-108.542182');
        Assert.isTrue(branch.Latitude__c == '45.765905' );
    }
   
    @isTest 
    static void getBranch_TestNotFound(){     
        Branch__c branch = CescoStockStorageHelper.getBranch('a1GcX000000m0coUAA');
        Assert.isTrue(branch == NULL);
    }
    @isTest 
    static void getBranchByBranchId_TestFieldsReturned(){     
        Branch__c existingBranch = [SELECT  Id FROM Branch__c Where Name='B054' LIMIT 1];
        Branch__c branch = CescoStockStorageHelper.getBranchByBranchId('B054');
        Assert.isTrue(branch.Cost_Per_SqFt_Monthly__c == 1.2);
        Assert.isTrue(branch.BranchAddress__c == '205 MOORE LN');
        Assert.isTrue(branch.BranchCity__c == 'Billings');
        Assert.isTrue(branch.BranchState__c == 'MT');
        Assert.isTrue(branch.BranchZip__c == '59101-3418');
        Assert.isTrue(branch.Racks__c == 3);
        Assert.isTrue(branch.Longitude__c == '-108.542182');
        Assert.isTrue(branch.Latitude__c == '45.765905' );

    }
    @isTest 
    static void getBranchByBranchId_TestNotFound(){     
        Branch__c branch = CescoStockStorageHelper.getBranchByBranchId('BXXX');
        Assert.isTrue(branch == NULL);
    }
    
    @isTest 
    static void getStockStorage_TestFieldsReturned(){
        stockStorageSetup();
        StockStorage__c stock = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
            Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
            PreparedBy__c, Project_Staging__c, SquareFootage__c, Value_of_Material_Being_Stored__c, CreatedDate, PreparedBy__r.Name, PreparedBy__r.Email,
            Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
            Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
            Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
            Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
            Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
            Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c,Cost_Per_SqFt_Monthly__c, Quote_Type__c
            FROM StockStorage__c  LIMIT 1];

        Test.startTest();
        StockStorage__c result = CescoStockStorageHelper.getStockStorage(stock.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(stock.Name, result.Name);
        System.assertEquals(stock.Job_Name__c, result.Job_Name__c);
        System.assertEquals(stock.Customer_Contact__c, result.Customer_Contact__c);
        System.assertEquals(stock.Number_of_Pallets__c, result.Number_of_Pallets__c);
        System.assertEquals(stock.Quote_Type__c, result.Quote_Type__c);
        System.assertEquals(stock.Cost_Per_SqFt_Monthly__c, result.Cost_Per_SqFt_Monthly__c);
        System.assertEquals(stock.Utilization_4X4_Cost__c, result.Utilization_4X4_Cost__c);
        System.assertEquals(stock.Utilization_4X8_Cost__c, result.Utilization_4X8_Cost__c);
        System.assertEquals(stock.Number_of_4X12_Pallets__c, result.Number_of_4X12_Pallets__c);
        System.assertEquals(stock.Most_Recent_PDF__c, result.Most_Recent_PDF__c);
        System.assertEquals(stock.Ship_To_Street__c, result.Ship_To_Street__c);
        System.assertEquals(stock.Ship_To_State__c, result.Ship_To_State__c);
        System.assertEquals(stock.Ship_To_Postal_Code__c, result.Ship_To_Postal_Code__c);
        System.assertEquals(stock.Ship_To_Country__c, result.Ship_To_Country__c);
        System.assertEquals(stock.Ship_To_City__c, result.Ship_To_City__c);
        System.assertEquals(stock.Total_Cost_of_Delivery__c, result.Total_Cost_of_Delivery__c);
        System.assertEquals(stock.Additional_Freight_Cost__c, result.Additional_Freight_Cost__c);        
        System.assertEquals(stock.First_Delivery_Date_To_Job_Site__c, result.First_Delivery_Date_To_Job_Site__c);        
        System.assertEquals(stock.First_Delivery_To_Branch__c, result.First_Delivery_To_Branch__c);        
        System.assertEquals(stock.Last_Delivery_Date_To_Job_Site__c, result.Last_Delivery_Date_To_Job_Site__c);
        System.assertEquals(stock.Margin__c, result.Margin__c);
        System.assertEquals(stock.Months_Material_Stored__c, result.Months_Material_Stored__c);
        System.assertEquals(stock.Ship_To_Latitude__c, result.Ship_To_Latitude__c);
        System.assertEquals(stock.Total_Cost__c, result.Total_Cost__c);
        System.assertEquals(stock.Total_Sales_Price__c, result.Total_Sales_Price__c);
        System.assertEquals(stock.Value_of_Material_Being_Stored__c, result.Value_of_Material_Being_Stored__c);
        System.assertEquals(stock.Value_of_Material_Being_Stored__c, result.Value_of_Material_Being_Stored__c);
        System.assertEquals(stock.SquareFootage__c, result.SquareFootage__c);
        System.assertEquals(stock.PreparedBy__c, result.PreparedBy__c);
        System.assertEquals(stock.Branch__c, result.Branch__c);
        System.assertEquals(stock.StockStorage_Opportunity__c, result.StockStorage_Opportunity__c);
        System.assertEquals(stock.StockStorage_Date__c, result.StockStorage_Date__c);
        System.assertEquals(stock.Staging_Pallet_Square_Feet__c, result.Staging_Pallet_Square_Feet__c);
        System.assertEquals(stock.StockStorage_Opportunity__c, result.StockStorage_Opportunity__c);
    }
    @isTest 
    static void getStockStorage_TestNotFound(){
        StockStorage__c result = CescoStockStorageHelper.getStockStorage('006cX000008lfO6QAI');
        Assert.isNull((result));
    }
    @isTest 
    static void getStockStorageByOppId_TestFieldsReturned(){       
        stockStorageSetup();
        Opportunity existingOpp = [SELECT Id,Name FROM Opportunity WHERE Name LIKE '%bidAccount%' LIMIT 1];
        StockStorage__c stock = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
            Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
            PreparedBy__c, Project_Staging__c, SquareFootage__c, Value_of_Material_Being_Stored__c, CreatedDate, PreparedBy__r.Name, PreparedBy__r.Email,
            Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
            Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
            Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
            Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
            Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
            Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c,Cost_Per_SqFt_Monthly__c, Quote_Type__c
            FROM StockStorage__c  LIMIT 1];
        Test.startTest();
      //  Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        StockStorage__c result = CescoStockStorageHelper.getStockStorageByOppId(existingOpp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(stock.Name, result.Name);
        System.assertEquals(stock.Job_Name__c, result.Job_Name__c);
        System.assertEquals(stock.Customer_Contact__c, result.Customer_Contact__c);
        System.assertEquals(stock.Number_of_Pallets__c, result.Number_of_Pallets__c);
        System.assertEquals(stock.Quote_Type__c, result.Quote_Type__c);
        System.assertEquals(stock.Cost_Per_SqFt_Monthly__c, result.Cost_Per_SqFt_Monthly__c);
        System.assertEquals(stock.Utilization_4X4_Cost__c, result.Utilization_4X4_Cost__c);
        System.assertEquals(stock.Utilization_4X8_Cost__c, result.Utilization_4X8_Cost__c);
        System.assertEquals(stock.Number_of_4X12_Pallets__c, result.Number_of_4X12_Pallets__c);
        System.assertEquals(stock.Most_Recent_PDF__c, result.Most_Recent_PDF__c);
        System.assertEquals(stock.Ship_To_Street__c, result.Ship_To_Street__c);
        System.assertEquals(stock.Ship_To_State__c, result.Ship_To_State__c);
        System.assertEquals(stock.Ship_To_Postal_Code__c, result.Ship_To_Postal_Code__c);
        System.assertEquals(stock.Ship_To_Country__c, result.Ship_To_Country__c);
        System.assertEquals(stock.Ship_To_City__c, result.Ship_To_City__c);
        System.assertEquals(stock.Total_Cost_of_Delivery__c, result.Total_Cost_of_Delivery__c);
        System.assertEquals(stock.Additional_Freight_Cost__c, result.Additional_Freight_Cost__c);        
        System.assertEquals(stock.First_Delivery_Date_To_Job_Site__c, result.First_Delivery_Date_To_Job_Site__c);        
        System.assertEquals(stock.First_Delivery_To_Branch__c, result.First_Delivery_To_Branch__c);        
        System.assertEquals(stock.Last_Delivery_Date_To_Job_Site__c, result.Last_Delivery_Date_To_Job_Site__c);
        System.assertEquals(stock.Margin__c, result.Margin__c);
        System.assertEquals(stock.Months_Material_Stored__c, result.Months_Material_Stored__c);
        System.assertEquals(stock.Ship_To_Latitude__c, result.Ship_To_Latitude__c);
        System.assertEquals(stock.Total_Cost__c, result.Total_Cost__c);
        System.assertEquals(stock.Total_Sales_Price__c, result.Total_Sales_Price__c);
        System.assertEquals(stock.Value_of_Material_Being_Stored__c, result.Value_of_Material_Being_Stored__c);
        System.assertEquals(stock.Value_of_Material_Being_Stored__c, result.Value_of_Material_Being_Stored__c);
        System.assertEquals(stock.SquareFootage__c, result.SquareFootage__c);
        System.assertEquals(stock.PreparedBy__c, result.PreparedBy__c);
        System.assertEquals(stock.Branch__c, result.Branch__c);
        System.assertEquals(stock.StockStorage_Opportunity__c, result.StockStorage_Opportunity__c);
        System.assertEquals(stock.StockStorage_Date__c, result.StockStorage_Date__c);
        System.assertEquals(stock.Staging_Pallet_Square_Feet__c, result.Staging_Pallet_Square_Feet__c);
        System.assertEquals(stock.StockStorage_Opportunity__c, result.StockStorage_Opportunity__c);
    }
    @isTest 
    static void getStockStorageByOppId_TestNotFound(){
        StockStorage__c result = CescoStockStorageHelper.getStockStorageByOppId('006cX000008lfO6QAI');
        Assert.isNull((result));
    }
    @isTest 
    static void getStockStorages_TestListReturned(){
        stockStorageSetup();
        List<StockStorage__c> result = CescoStockStorageHelper.getStockStorages();
        Assert.isTrue(result.size() > 0 );
    }
    static void stockStorageSetup(){
        Contact contact = [SELECT Id From Contact Where Email = 'terry@test.com'];
        Opportunity pcbOpp = [SELECT Id From Opportunity Where Name='Test PCB Opp' LIMIT 1];
        Account pcbAccount = [SELECT Id From Account Where Name = '*Project*'];
        Account bidAccount = [SELECT Id From Account Where Name = 'bidAccount'];
        Branch__c branch = CescoStockStorageHelper.getBranchByBranchId('B054');
        Opportunity existingOpp = new Opportunity(Name = 'Test Opportunity', AccountId= bidAccount.Id, StageName = 'RFP/RFQ', CloseDate = Date.valueOf(System.now() + 10),
            Related_Parent_Construction_Bid__c = pcbOpp.Id,Customer_Contact__c = contact.Id, Super_District__c = 'SDBIGSKY', Branch__c = 'B054');
        insert existingOpp;
        User testUser1 = new User(Alias = 'stadt1', Email='standarduser2@testorg.com',EmailEncodingKey='UTF-8',LastName='Testing', FirstName = 'Tina',
        LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = saProfile.Id,TimeZoneSidKey='America/Los_Angeles',
         UserName='standarduser1'+Math.random()+'@testorg.com', Phone='9998887751');
        INSERT testUser1;
        StockStorage__c stock = new StockStorage__c(
            Name = 'Test Storage',
            Job_Name__c = 'Test Job',
            Customer_Contact__c = contact.Id,
            Number_of_Pallets__c = 10,
            Staging_Pallet_Square_Feet__c = 100.0,
            StockStorage_Date__c = Date.today(),
            StockStorage_Opportunity__c = existingOpp.Id,
            Branch__c = branch.Id,
            PreparedBy__c = testUser1.Id,
            SquareFootage__c = 500.0,
            Value_of_Material_Being_Stored__c = 10000.0,
            Total_Sales_Price__c = 15000.0,
            Total_Cost__c = 12000.0,
            Ship_To_Longitude__c = -90.0,
            Ship_To_Latitude__c = 40.0,
            Months_Material_Stored__c = 3,
            Margin__c = 30.0,
            Last_Delivery_Date_To_Job_Site__c = Date.today().addDays(-1),
            First_Delivery_To_Branch__c = Date.today().addDays(-10),
            First_Delivery_Date_To_Job_Site__c = Date.today().addDays(-15),
            Additional_Freight_Cost__c = 500.0,
            Total_Cost_of_Delivery__c = 2000.0,
            Ship_To_City__c = 'Dubuque',
            Ship_To_Country__c = 'USA',
            Ship_To_Postal_Code__c = '52001',
            Ship_To_State__c = 'IA',
            Ship_To_Street__c = '123 Main St',
            Most_Recent_PDF__c = '123456',
            Number_of_4X8_Pallets__c = 4,
            Number_of_4X12_Pallets__c = 2,
            Number_of_4X4_Pallets__c = 3,
            Estimated_Number_of_Deliveries__c = 10,
            Material_Handling_Fee__c = 250.0,
            Staging_Square_Footage_Cost__c = 1.5,
            Utilization_4X12_Cost__c = 100.0,
            Utilization_4X8_Cost__c = 80.0,
            Utilization_4X4_Cost__c = 60.0,
            Cost_Per_SqFt_Monthly__c = 2.0,
            Quote_Type__c = 'Bill and Hold'
        );
        insert stock;
    }
    @isTest 
    static void getBoxFolderIdForPCBOpportunity_TestFieldsReturned(){
        Opportunity pcbOpp = [SELECT Id From Opportunity Where Name='Test PCB Opp' LIMIT 1];
        box__FRUP__C frup = new box__FRUP__c();
        frup.box__Folder_ID__c = '12345';
        frup.box__Object_Name__c = 'Opportunity';  
        frup.box__Record_ID__c = pcbOpp.Id;
        insert frup;

        box__FRUP__c frup2 = CescoStockStorageHelper.getBoxFolderIdForPCBOpportunity(pcbOpp.Id);

        Assert.isTrue(frup2.box__Folder_ID__c == frup.box__Folder_ID__c);        

    }
    @isTest 
    static void getBoxFolderIdForPCBOpportunity_TestNotFound(){
        box__FRUP__c frup2 = CescoStockStorageHelper.getBoxFolderIdForPCBOpportunity('006cX000008lfO6QAI');

        Assert.isNull(frup2); 
    }
    @isTest 
    static void updateStockStorage_TestUpdateWorks(){
        stockStorageSetup();
        Opportunity existingOpp = [SELECT Id,Name FROM Opportunity WHERE Name LIKE '%bidAccount%' LIMIT 1];
        StockStorage__c stock = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
            Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
            PreparedBy__c, Project_Staging__c, SquareFootage__c,  Value_of_Material_Being_Stored__c, CreatedDate, PreparedBy__r.Name, PreparedBy__r.Email,
            Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
            Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
            Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
            Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
            Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
            Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c,Cost_Per_SqFt_Monthly__c, Quote_Type__c
            FROM StockStorage__c  LIMIT 1];

        Test.startTest();
        stock.Number_of_4X4_Pallets__c = 1;
        StockStorage__c result = CescoStockStorageHelper.updateStockStorage(stock);
        Test.stopTest();
        StockStorage__c updatedStock = [SELECT Id, Name, Number_of_4X4_Pallets__c FROM StockStorage__c WHERE Id = :stock.Id LIMIT 1];

        Assert.isTrue(updatedStock.Number_of_4X4_Pallets__c == 1);

    }
   

@isTest
static void testGeneratePdf_testMethodExists() {        

        // Create test StockStorage__c record
        stockStorageSetup();
        StockStorage__c stock = [SELECT Id, Name, Job_Name__c, Customer_Contact__c, Number_of_Pallets__c, 
            Staging_Pallet_Square_Feet__c,StockStorage_Date__c,StockStorage_Opportunity__c, Branch__c,
            PreparedBy__c, Project_Staging__c, SquareFootage__c, Value_of_Material_Being_Stored__c, CreatedDate, PreparedBy__r.Name, PreparedBy__r.Email,
            Total_Sales_Price__c, Total_Cost__c, Ship_To_Longitude__c, Ship_To_Latitude__c, Months_Material_Stored__c, Margin__c,
            Last_Delivery_Date_To_Job_Site__c, First_Delivery_To_Branch__c, First_Delivery_Date_To_Job_Site__c, 
            Additional_Freight_Cost__c, Total_Cost_of_Delivery__c,
            Ship_To_City__c, Ship_To_Country__c, Ship_To_Postal_Code__c, Ship_To_State__c, Ship_To_Street__c, Most_Recent_PDF__c, Number_of_4X8_Pallets__c,
            Number_of_4X12_Pallets__c, Number_of_4X4_Pallets__c, Estimated_Number_of_Deliveries__c, Material_Handling_Fee__c, Staging_Square_Footage_Cost__c,
            Utilization_4X12_Cost__c,Utilization_4X8_Cost__c,Utilization_4X4_Cost__c,Cost_Per_SqFt_Monthly__c, Quote_Type__c
            FROM StockStorage__c  LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CescoBoxApiCalloutMockStatus200());
        Test.startTest();

        CescoStockStorageHelper.generatePdf(stock.Id,'test@example.com');
        Test.stopTest();

        // Add assertions if your method has side effects you can verify
        // For example, if a record is created or updated, assert that
    }

     @isTest 
    static void getDrivingDistanceByAddress_TestNoStartAddress() {
        try{
            String startAddress = '';
            String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
            // Act
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        }
        catch(Exception e){
            System.Assert.isTrue(e.getMessage().contains('Origin and destination addresses are required'), 'Should throw exception for no start address');
        }
    }
    @isTest 
    static void getDrivingDistanceByAddress_TestNoEndAddress() {
        try{
            String startAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
            String endAddress = '';
            // Act
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        }
        catch(Exception e){
            System.Assert.isTrue(e.getMessage().contains('Origin and destination addresses are required'), 'Should throw exception for no start address');
        }
    }
    @isTest 
    static void getDrivingDistanceByAddress_Test200_ReturnsMiles() {
        // Arrange mock for Google Distance Matrix 200 response with "7.7 mi"
        Test.setMock(HttpCalloutMock.class, new CescoMockGoogleMapsDistanceMatrixResponse200('7.7 mi'));
        String startAddress = '5505 PATTERSON AVE SE STE 100, KENTWOOD, MI, 49512';
        String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
        // Act
        Test.startTest();
        Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, miles, 'Miles should not be null');
        System.assertEquals(7.7, miles, 'Parsed miles should match the distance text');
    }
    @isTest 
    static void getDrivingDistanceByAddress_Test200_ButNoDistanceText() {
        try{
            // Arrange mock for Google Distance Matrix 200 response with "7.7 mi"
            Test.setMock(HttpCalloutMock.class, new CescoMockGoogleMapsDistanceMatrixResponseNoDistanceText());
            String startAddress = '5505 PATTERSON AVE SE STE 100, KENTWOOD, MI, 49512';
            String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
            // Act
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        }
        catch(Exception e){
               System.Assert.isTrue(e.getMessage().contains('Distance text not found in API response'), 'Should throw CalloutException for non-200');
         
        }
    }
    @isTest 
    static void getDrivingDistanceByAddress_Test200_ButNoDistance() {
        try{
            Test.setMock(HttpCalloutMock.class, new CescoMockGoogleMapsDistanceMatrixResponseNoDistance('7.7 mi'));
            String startAddress = '5505 PATTERSON AVE SE STE 100, KENTWOOD, MI, 49512';
            String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
            // Act
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        }
        catch(Exception e){
            System.Assert.isTrue(e.getMessage().contains('Distance data not available in API response'), 'Should throw CalloutException for non-200');
        }
    }

    @isTest 
    static void getDrivingDistanceByAddress_TestNon200_Throws() {
        // Arrange mock for non-200 response
        Test.setMock(HttpCalloutMock.class, new CescoMockGoogleMapsDistanceMatrixResponseNon200(500));
        String startAddress = '5505 PATTERSON AVE SE STE 100, KENTWOOD, MI, 49512';
        String endAddress = '648 Ottawa Avenue Northwest, Grand Rapids, MI, 59503';
        // Act + Assert
        Boolean threw = false;
        try {
            Test.startTest();
            Double miles = CescoStockStorageHelper.getDrivingDistanceByAddress(startAddress, endAddress);
            Test.stopTest();
        } catch (Exception e) {
            threw = true;
            System.assert(e.getMessage().contains('Google Maps Distance API Error'), 'Should throw CalloutException for non-200');
        }
        System.assertEquals(true, threw, 'Expected exception to be thrown for non-200 response');
    }
    
    /**
     * Mock: Google Distance Matrix non-200 response
     */
    private class CescoMockGoogleMapsDistanceMatrixResponseNon200 implements HttpCalloutMock {
        private Integer code;
        CescoMockGoogleMapsDistanceMatrixResponseNon200(Integer code) {
            this.code = code;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody('{"error_message":"Server error","status":"UNKNOWN_ERROR"}');
            return res;
        }
    }

    /**
     * Mock: Google Distance Matrix 200 but empty rows
     */
    private class CescoMockGoogleMapsDistanceMatrixResponseEmptyRows implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"rows":[],"status":"OK"}');
            return res;
        }
    }
    // ========== MOCKS FOR GOOGLE DISTANCE MATRIX ==========
    /**
     * Mock: Google Distance Matrix success with configurable distance text (e.g., "7.7 mi")
     */
    private class CescoMockGoogleMapsDistanceMatrixResponse200 implements HttpCalloutMock {
        private String distanceText;
        CescoMockGoogleMapsDistanceMatrixResponse200(String distanceText) {
            this.distanceText = distanceText;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Minimal valid Distance Matrix JSON
            String body = '{"rows":[{"elements":[{"status":"OK","distance":{"text":"' + distanceText + '","value":12345},"duration":{"text":"15 mins","value":900}}]}],"status":"OK"}';
            res.setBody(body);
            return res;
        }        
    }
    // ========== MOCKS FOR GOOGLE DISTANCE MATRIX ==========
    /**
     * Mock: Google Distance Matrix success with configurable distance text (e.g., "7.7 mi")
     */
    private class CescoMockGoogleMapsDistanceMatrixResponseNoDistance implements HttpCalloutMock {
        private String distanceText;
        CescoMockGoogleMapsDistanceMatrixResponseNoDistance(String distanceText) {
            this.distanceText = distanceText;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Minimal valid Distance Matrix JSON
            String body = '{"rows":[{"elements":[{"status":"OK","xxx":{"text":"' + distanceText + '","value":12345},"duration":{"text":"15 mins","value":900}}]}],"status":"OK"}';
            res.setBody(body);
            return res;
        }        
    } 
     // ========== MOCKS FOR GOOGLE DISTANCE MATRIX ==========
    /**
     * Mock: Google Distance Matrix success with configurable distance text (e.g., "7.7 mi")
     */
    private class CescoMockGoogleMapsDistanceMatrixResponseNoDistanceText implements HttpCalloutMock {      
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Minimal valid Distance Matrix JSON
            String body = '{"rows":[{"elements":[{"status":"OK","distance":{"xxxx":"' + 'xx' + '","value":12345},"duration":{"text":"15 mins","value":900}}]}],"status":"OK"}';
            res.setBody(body);
            return res;
        }        
    }     
    

}