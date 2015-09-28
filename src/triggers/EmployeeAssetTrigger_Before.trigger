trigger EmployeeAssetTrigger_Before on EmployeeAssetJunction__c (before insert, before update) {
	List<Asset__c> lstAss = new List<Asset__c>();
    for(EmployeeAssetJunction__c eaObj : trigger.new) {
        eaObj.IsUnique__c = eaObj.Employee_Number__c + '-' + eaObj.Asset__c;
    }
    if(trigger.isUpdate) {
        for(EmployeeAssetJunction__c eaObj : trigger.new) {
            if(eaObj.Employee_Number__c != trigger.oldMap.get(eaObj.Id).Employee_Number__c ) {
                eaObj.Asset_Assigned_Date__c = System.today();
            }
        }
          try{
	        for(EmployeeAssetJunction__c objEAJ : trigger.new){
	        	if(objEAJ.Asset__c != null && objEAJ.Current_Active_Owner__c != trigger.oldMap.get(objEAJ.id).Current_Active_Owner__c){
	        		Asset__c objAsset= new Asset__c(id = objEAJ.Asset__c);
	        		objAsset.Current_Active_Owner__c = objEAJ.Current_Active_Owner__c;
	        		lstAss.add(objAsset);
	           	}
	        }
	        if(lstAss != null && lstAss.size()>0){
        		update lstAss;
	        }
        }catch(exception ex){}
    }
    
}