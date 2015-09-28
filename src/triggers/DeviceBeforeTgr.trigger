trigger DeviceBeforeTgr on Device__c (before insert, before update) {
	//check if Device record is shared from Telus then re-Parent to correct parent(case)
	List<Device__c> TelusDeviceList = new List<Device__c>();
	List<Device__c> returnedDeviceList = new List<Device__c>();
	List<Device__c> localDeviceList = new List<Device__c>();
	if(Trigger.isInsert){
		for(Device__c dev : Trigger.new){
			// populating localCase Id Field 
			if(dev.ConnectionReceivedId == NULL){// Local record
				localDeviceList.add(dev);
			}
			if(Dev.Case__c != NULL ){
				Dev.Local_Parent_Id__c = Dev.Case__c;
				System.debug('@@@@@@@@@@@@@@@@ Device Share : '+ Dev.Local_Parent_Id__c + '+++++++++++++=== '+ Dev.Case__c);
			}
			if(dev.ConnectionReceivedId != NULL
					&& S2SConnectionHelperCls.getConnectionId('TELUS') != NULL 
					&& S2SConnectionHelperCls.getConnectionId('TELUS').contains(dev.ConnectionReceivedId)){
				TelusDeviceList.add(dev);
				system.debug('&&&&&&&&&&&&&&&&&&&&&&&77 '+dev.Partner_Parent_ID__c);
			}
		}
		if(TelusDeviceList.size() > 0){
			TelusExternalSharingHelperCls.reParentToCaseOnRC(TelusDeviceList);
		}
		if(localDeviceList.size() > 0){
			TelusExternalSharingHelperCls.populatePartnerCaseIdOnDevice(localDeviceList);
		}
	}
	if(Trigger.isUpdate){
		for(Device__c dev : Trigger.new){
			if(dev.Returned_Date__c != NULL && Trigger.oldMap.get(dev.id).Returned_Date__c != dev.Returned_Date__c){
				returnedDeviceList.add(dev);
			} 
		}	
		if(returnedDeviceList.size() > 0){
			//TelusExternalSharingHelperCls.stopDeviceSharing(returnedDeviceList);
		}
	}
}