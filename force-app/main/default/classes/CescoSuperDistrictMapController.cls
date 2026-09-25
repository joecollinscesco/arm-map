/**
 * Apex controller for the Cesco Agency Map LWC component.
 *
 * Provides data access methods for displaying super districts, their associated
 * agencies, suppliers linked to those agencies, and detailed account/contact
 * information. All methods are exposed via @AuraEnabled for use in Lightning
 * components.
 *
 * Data model relationships:
 *   Super_District__c  ←─ Agency_Super_District__c ─→ Account (Agency)
 *   Account (Agency)   ←─ Supplier_Agency_Contact__c ─→ Account (Supplier)
 */
public with sharing class CescoSuperDistrictMapController {

    /**
     * Returns all Super District records with geolocation and display fields
     * needed to render district markers on the map.
     */
    @AuraEnabled(cacheable=false)
    public static List<Super_District__c> getSuperDistricts() {

        List<Super_District__c> districts = [
            SELECT
                Id,
                Name,
                Geolocation__Latitude__s,
                Geolocation__Longitude__s,
                SuperDistrictID__c,
                Html_Color__c,
                Html_Fore_Color__c
            FROM Super_District__c
        ];
        return districts;
    }

    /**
     * Returns all agency Accounts associated with a given Super District.
     * Resolves the many-to-many relationship through Agency_Super_District__c.
     *
     * @param superDistrictId  The Id of the Super_District__c record to filter by.
     * @return List of matching Account records with billing address fields.
     */
    @AuraEnabled(cacheable=false)
    public static List<Account> getAgenciesForSuperDistrict(Id superDistrictId) {

        // Collect agency Account Ids linked to this super district
        List<Id> agencyAccountIds = new List<Id>();
        for (Agency_Super_District__c sd : [
            SELECT Agency_Account__c
            FROM Agency_Super_District__c
            WHERE Super_District__r.Id = :superDistrictId
        ]) {
            agencyAccountIds.add(sd.Agency_Account__c);
        }

        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                BillingPostalCode, BillingCountry, Website
            FROM Account
            WHERE Id IN :agencyAccountIds
        ];
    }

    /**
     * Returns all unique supplier Accounts that are linked to any agency
     * within the given Super District.
     *
     * Walk: Super District → Agency_Super_District__c → Agency Accounts
     *       → Supplier_Agency_Contact__c → Supplier Accounts
     *
     * @param superDistrictId  The Id of the Super_District__c to scope the lookup.
     * @return List of supplier Account records (Id and Name only).
     */
    @AuraEnabled(cacheable=false)
    public static List<Account> getAgencySuppliers(Id superDistrictId) {
        System.debug('superDistrictID:' + superDistrictId);

        // Step 1: get all agency Account Ids in this super district
        Set<Id> agencyAccountIds = new Set<Id>();
        for (Agency_Super_District__c asd : [
            SELECT Agency_Account__c
            FROM Agency_Super_District__c
            WHERE Super_District__c = :superDistrictId
        ]) {
            agencyAccountIds.add(asd.Agency_Account__c);
        }
        System.debug('agencyAccountIds:' + agencyAccountIds);

        // Step 2: find all suppliers linked to those agencies
        Set<Id> supplierAgencyIds = new Set<Id>();
        for (Supplier_Agency_Contact__c sac : [
            SELECT Supplier__c
            FROM Supplier_Agency_Contact__c
            WHERE Agency__c IN :agencyAccountIds
        ]) {
            supplierAgencyIds.add(sac.Supplier__c);
        }
        System.debug('supplierAgencyIds:' + supplierAgencyIds);

        // Step 3: return the supplier Account records
        List<Account> suppliers = [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :supplierAgencyIds
        ];
        System.debug('suppliers:' + suppliers);
        return suppliers;
    }

    /**
     * Returns all agency Accounts within a Super District that work with a
     * specific supplier. Used to highlight a supplier's footprint on the map.
     *
     * Walk: Supplier Account → Supplier_Agency_Contact__c → Agency Accounts
     *       → filtered by Agency_Super_District__c membership in superDistrictId
     *
     * @param supplierAccountId  The Id of the supplier Account to filter by.
     * @param superDistrictId    The Id of the Super_District__c to scope results.
     * @return List of agency Account records with billing address fields.
     */
    @AuraEnabled(cacheable=false)
    public static List<Account> getSupplierAgencies(Id supplierAccountId, Id superDistrictId) {

        // Step 1: collect all agencies this supplier is linked to
        Set<Id> supplierAgencyIds = new Set<Id>();
        for (Supplier_Agency_Contact__c sac : [
            SELECT Agency__c
            FROM Supplier_Agency_Contact__c
            WHERE Supplier__c = :supplierAccountId
        ]) {
            supplierAgencyIds.add(sac.Agency__c);
        }
        System.debug('supplierAgencyIds:' + supplierAgencyIds);

        // Step 2: narrow to agencies that also belong to the selected super district
        Set<Id> agencySdAccounts = new Set<Id>();
        for (Agency_Super_District__c asd : [
            SELECT Agency_Account__c
            FROM Agency_Super_District__c
            WHERE Agency_Account__c IN :supplierAgencyIds
              AND Super_District__c = :superDistrictId
        ]) {
            agencySdAccounts.add(asd.Agency_Account__c);
        }
        System.debug('agencySdAccounts:' + agencySdAccounts);

        List<Account> supplierAccounts = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                BillingPostalCode, BillingCountry, Website
            FROM Account
            WHERE Id IN :agencySdAccounts
        ];
        System.debug('supplierAccounts:' + supplierAccounts);
        return supplierAccounts;
    }

    @AuraEnabled(cacheable=false)
    public static Account getAccount(Id accountId) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                BillingPostalCode, BillingCountry, Website,
                (SELECT Id, FirstName, LastName, Title, Email, Phone, Website__c, Full_Name__c FROM Contacts)
            FROM Account
            WHERE Id = :accountId LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=false)
    public static List<Account> getAgencies(List<Id> accountIds) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                BillingPostalCode, BillingCountry, Website,
                (SELECT Id, FirstName, LastName, Title, Email, Phone, Website__c, Full_Name__c FROM Contacts)
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    


}