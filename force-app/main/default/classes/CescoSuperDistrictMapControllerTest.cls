@isTest
private class CescoSuperDistrictMapControllerTest {

    // ─── Test Data Setup ──────────────────────────────────────────────────────
    static Id agencyRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Agency').getRecordTypeId();
    static Id supplierRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
    @TestSetup
    static void setupTestData() {
        // Two super districts so we can verify cross-district isolation
        Super_District__c districtA = new Super_District__c(Name = 'District A', SuperDistrictID__c = 'SDNPLAINS');
        Super_District__c districtB = new Super_District__c(Name = 'District B', SuperDistrictID__c = 'SDBIGSKY');
        insert new List<Super_District__c>{ districtA, districtB };

        // Three agency accounts
        Account agencyA1 = new Account(Name = 'Agency A1', BillingStreet = '1 Main St',
            BillingCity = 'Chicago', BillingState = 'IL',
            BillingPostalCode = '60601', BillingCountry = 'US', RecordTypeId = agencyRecordTypeId);
        Account agencyA2 = new Account(Name = 'Agency A2', BillingStreet = '2 Oak Ave',
            BillingCity = 'Chicago', BillingState = 'IL',
            BillingPostalCode = '60602', BillingCountry = 'US', RecordTypeId = agencyRecordTypeId);
        Account agencyB1 = new Account(Name = 'Agency B1', BillingStreet = '3 Elm Rd',
            BillingCity = 'Springfield', BillingState = 'IL',
            BillingPostalCode = '62701', BillingCountry = 'US', RecordTypeId = agencyRecordTypeId);
        insert new List<Account>{ agencyA1, agencyA2, agencyB1 };

        // One supplier account
        Account supplier1 = new Account(Name = 'Supplier 1', RecordTypeId = supplierRecordTypeId);
        insert supplier1;

        // Link agencyA1 and agencyA2 to districtA; agencyB1 to districtB
        insert new List<Agency_Super_District__c>{
            new Agency_Super_District__c(Agency_Account__c = agencyA1.Id, Super_District__c = districtA.Id),
            new Agency_Super_District__c(Agency_Account__c = agencyA2.Id, Super_District__c = districtA.Id),
            new Agency_Super_District__c(Agency_Account__c = agencyB1.Id, Super_District__c = districtB.Id)
        };
        Contact c1 = new Contact();
        c1.FirstName = 'John';
        c1.LastName = 'Test';
        c1.Email = 'john.test@example.com';
        c1.AccountId = agencyA1.Id;
        insert c1;      

        // Link supplier1 to agencyA1 only — agencyA2 is intentionally unlinked
        insert new Supplier_Agency_Contact__c(
            Name = 'Supplier 1',
            Supplier__c = supplier1.Id,
            Agency__c    = agencyA1.Id,
            Contact__c = c1.Id
        );

        // Contact on agencyA1 for getAccountDetail tests
        insert new Contact(
            FirstName = 'Jane', LastName = 'Doe',
            Title = 'Manager', Email = 'jane@example.com',
            Phone = '312-555-0100', AccountId = agencyA1.Id
        );
    }

    // ─── getSuperDistricts ────────────────────────────────────────────────────

    @isTest
    static void getSuperDistricts_ReturnsBothDistricts() {
        // When
        Test.startTest();
        List<Super_District__c> result = CescoSuperDistrictMapController.getSuperDistricts();
        Test.stopTest();

        // Then
        Assert.areEqual(2, result.size(), 'Should return all super districts');
    }

    @isTest
    static void getSuperDistricts_IncludesRequiredFields() {
        // When
        Test.startTest();
        List<Super_District__c> result = CescoSuperDistrictMapController.getSuperDistricts();
        Test.stopTest();

        // Then — verify the query projected all map-display fields (non-null Id/Name at minimum)
        for (Super_District__c sd : result) {
            Assert.isNotNull(sd.Id,   'Id must be populated');
            Assert.isNotNull(sd.Name, 'Name must be populated');
        }
    }

    // ─── getAgenciesForSuperDistrict ──────────────────────────────────────────

    @isTest
    static void getAgenciesForSuperDistrict_ReturnsAgenciesInDistrict() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getAgenciesForSuperDistrict(districtA.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(2, result.size(), 'District A should have exactly 2 agencies');
        Set<String> names = new Set<String>();
        for (Account a : result) { names.add(a.Name); }
        Assert.isTrue(names.contains('Agency A1'), 'Agency A1 should be in District A');
        Assert.isTrue(names.contains('Agency A2'), 'Agency A2 should be in District A');
    }

    @isTest
    static void getAgenciesForSuperDistrict_ExcludesAgenciesInOtherDistricts() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getAgenciesForSuperDistrict(districtA.Id);
        Test.stopTest();

        // Then — Agency B1 belongs to District B and must not appear
        Set<String> names = new Set<String>();
        for (Account a : result) { names.add(a.Name); }
        Assert.isFalse(names.contains('Agency B1'), 'Agency B1 should not appear in District A results');
    }

    @isTest
    static void getAgenciesForSuperDistrict_ReturnsBillingAddressFields() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getAgenciesForSuperDistrict(districtA.Id);
        Test.stopTest();

        // Then — spot-check one record to confirm projected fields are populated
        Account a1 = null;
        for (Account a : result) { if (a.Name == 'Agency A1') { a1 = a; break; } }
        Assert.isNotNull(a1, 'Agency A1 must be present');
        Assert.areEqual('1 Main St', a1.BillingStreet,  'BillingStreet should match');
        Assert.areEqual('Chicago',   a1.BillingCity,    'BillingCity should match');
        Assert.areEqual('IL',        a1.BillingState,   'BillingState should match');
        Assert.areEqual('60601',     a1.BillingPostalCode, 'BillingPostalCode should match');
    }

    // ─── getAgencySuppliers ───────────────────────────────────────────────────

    @isTest
    static void getAgencySuppliers_ReturnsSuppliersForDistrict() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getAgencySuppliers(districtA.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.size(), 'District A should have 1 supplier');
        Assert.areEqual('Supplier 1', result[0].Name, 'Supplier name should match');
    }

    @isTest
    static void getAgencySuppliers_ReturnsEmpty_WhenNoSuppliersLinked() {
        // Given — District B's agency has no Supplier_Agency_Contact__c records
        Super_District__c districtB = [SELECT Id FROM Super_District__c WHERE Name = 'District B' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getAgencySuppliers(districtB.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(0, result.size(), 'District B should have no suppliers');
    }

   

    // ─── getSupplierAgencies ──────────────────────────────────────────────────

    @isTest
    static void getSupplierAgencies_ReturnsAgenciesForSupplierInDistrict() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];
        Account supplier1 = [SELECT Id FROM Account WHERE Name = 'Supplier 1' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getSupplierAgencies(supplier1.Id, districtA.Id);
        Test.stopTest();

        // Then — only agencyA1 is linked to supplier1; agencyA2 is not
        Assert.areEqual(1, result.size(), 'Should return exactly 1 agency linked to Supplier 1 in District A');
        Assert.areEqual('Agency A1', result[0].Name, 'Agency A1 should be returned');
    }

    @isTest
    static void getSupplierAgencies_ExcludesAgenciesInOtherDistrict() {
        // Given — supplier1 is linked to agencyA1 (District A), not District B
        Super_District__c districtB = [SELECT Id FROM Super_District__c WHERE Name = 'District B' LIMIT 1];
        Account supplier1 = [SELECT Id FROM Account WHERE Name = 'Supplier 1' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getSupplierAgencies(supplier1.Id, districtB.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(0, result.size(), 'Supplier has no agencies in District B');
    }

    @isTest
    static void getSupplierAgencies_ReturnsBillingAddressFields() {
        // Given
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];
        Account supplier1 = [SELECT Id FROM Account WHERE Name = 'Supplier 1' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getSupplierAgencies(supplier1.Id, districtA.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.size(), 'Expect one result to check fields on');
        Assert.areEqual('1 Main St', result[0].BillingStreet,  'BillingStreet should be populated');
        Assert.areEqual('Chicago',   result[0].BillingCity,    'BillingCity should be populated');
        Assert.areEqual('IL',        result[0].BillingState,   'BillingState should be populated');
        Assert.areEqual('60601',     result[0].BillingPostalCode, 'BillingPostalCode should be populated');
    }

    @isTest
    static void getSupplierAgencies_ReturnsEmpty_WhenSupplierHasNoAgencies() {
        // Given — brand-new supplier with no Supplier_Agency_Contact__c links
        Account newSupplier = new Account(Name = 'Unlinked Supplier');
        insert newSupplier;
        Super_District__c districtA = [SELECT Id FROM Super_District__c WHERE Name = 'District A' LIMIT 1];

        // When
        Test.startTest();
        List<Account> result = CescoSuperDistrictMapController.getSupplierAgencies(newSupplier.Id, districtA.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(0, result.size(), 'Unlinked supplier should return no agencies');
    }

  


}