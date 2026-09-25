declare module "@salesforce/apex/CescoSuperDistrictMapController.getSuperDistricts" {
  export default function getSuperDistricts(): Promise<any>;
}
declare module "@salesforce/apex/CescoSuperDistrictMapController.getAgenciesForSuperDistrict" {
  export default function getAgenciesForSuperDistrict(param: {superDistrictId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoSuperDistrictMapController.getAgencySuppliers" {
  export default function getAgencySuppliers(param: {superDistrictId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoSuperDistrictMapController.getSupplierAgencies" {
  export default function getSupplierAgencies(param: {supplierAccountId: any, superDistrictId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoSuperDistrictMapController.getAccount" {
  export default function getAccount(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoSuperDistrictMapController.getAgencies" {
  export default function getAgencies(param: {accountIds: any}): Promise<any>;
}
