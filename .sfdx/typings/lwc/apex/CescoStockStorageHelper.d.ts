declare module "@salesforce/apex/CescoStockStorageHelper.getAccount" {
  export default function getAccount(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getOpportunity" {
  export default function getOpportunity(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getContact" {
  export default function getContact(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getUser" {
  export default function getUser(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getBranch" {
  export default function getBranch(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getBranchByBranchId" {
  export default function getBranchByBranchId(param: {branchId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getStockStorage" {
  export default function getStockStorage(param: {id: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getStockStorageByOppId" {
  export default function getStockStorageByOppId(param: {oppId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getStockStorages" {
  export default function getStockStorages(): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getBoxFolderIdForPCBOpportunity" {
  export default function getBoxFolderIdForPCBOpportunity(param: {oppId: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.updateStockStorage" {
  export default function updateStockStorage(param: {stockStorage: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.generatePdf" {
  export default function generatePdf(param: {stockStorageId: any, emailToSendPdfTo: any}): Promise<any>;
}
declare module "@salesforce/apex/CescoStockStorageHelper.getDrivingDistanceByAddress" {
  export default function getDrivingDistanceByAddress(param: {originAddress: any, destAddress: any}): Promise<any>;
}
