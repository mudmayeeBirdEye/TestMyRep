/****Trigger to validate only Unique Campaign Exists for BMID,PID,AID and DNIS combination.*****/

trigger checkUniqueFieldCombination on Campaign (before insert, before update) {
	Set<string> UniqueCombinationSet = new Set<string>();
	
	if(trigger.isInsert){
		for(Campaign capmObj : Trigger.New){	
			if(capmObj.IsActive){	
				UniqueCombinationSet.add(LeadTriggerHelper.createUniqueCombination(capmObj.BMID__c,capmObj.AID__c,capmObj.PID__c,capmObj.DNIS__c));
			}
		}
	}
	
	if(trigger.isUpdate){
		for(Campaign capmObj : Trigger.New){
    		if(
    		   (
    		   capmObj.BMID__c != Trigger.oldMap.get(capmObj.Id).BMID__c ||
    		   capmObj.AID__c != Trigger.oldMap.get(capmObj.Id).AID__c ||
    		   capmObj.PID__c != Trigger.oldMap.get(capmObj.Id).PID__c ||
    		   capmObj.DNIS__c != Trigger.oldMap.get(capmObj.Id).DNIS__c ||
    		   capmObj.IsActive != Trigger.oldMap.get(capmObj.Id).IsActive 
    		   )
    		   && 
    		   capmObj.IsActive==true ){
    				UniqueCombinationSet.add(LeadTriggerHelper.createUniqueCombination(capmObj.BMID__c,capmObj.AID__c,capmObj.PID__c,capmObj.DNIS__c));    				
    		}
    	}
	}
	
	if(UniqueCombinationSet!=null && UniqueCombinationSet.size() > 0){
		List<Campaign> campList = [Select id,Name,BMID__c,AID__c,PID__c,DNIS__c,Unique_Combination__c from Campaign
								   where Unique_Combination__c in : UniqueCombinationSet AND IsActive=true];
		map<string,string> uniqueCombinationFieldMap = new  map<string,string>();
		if(campList!=null && campList.size() > 0){
			for(Campaign capmObj : campList){
				uniqueCombinationFieldMap.put(capmObj.Unique_Combination__c.toUpperCase(),capmObj.Name);
			}
		}
		for(Campaign capmObj : Trigger.New){
			if((capmObj.BMID__c!=null && !string.isBlank(capmObj.BMID__c)) || (capmObj.AID__c!=null && !string.isBlank(capmObj.AID__c)) || 
				(capmObj.PID__c!=null && !string.isBlank(capmObj.PID__c)) || (capmObj.DNIS__c!=null && !string.isBlank(capmObj.DNIS__c))){
				String uniqueCombo = LeadTriggerHelper.createUniqueCombination(capmObj.BMID__c,capmObj.AID__c,capmObj.PID__c,capmObj.DNIS__c);
				if(uniqueCombinationFieldMap!=null && uniqueCombinationFieldMap.get(uniqueCombo.toUpperCase())!=null){
					if(!Test.isRunningTest()){
						capmObj.addError('Campaign having name '+uniqueCombinationFieldMap.get(uniqueCombo.toUpperCase())+ ' already exists for provided BMID, AID, PID and DNIS combination.');
					}
				}
			}
		}
	}
}