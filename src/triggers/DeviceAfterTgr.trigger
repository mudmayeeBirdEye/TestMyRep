trigger DeviceAfterTgr on Device__c (after insert, after update) {
	List<Device__c> localDeviceList = new List<Device__c>();
	List<Device__c> TelusDeviceList = new List<Device__c>();
	List<Device__c> returnedDeviceList = new List<Device__c>();
	if(Trigger.isInsert){
		for(Device__c dev : Trigger.new){
			if(dev.ConnectionReceivedId == NULL){// Local record
				localDeviceList.add(dev);
			}
		}
		if(localDeviceList.size() > 0){
			TelusExternalSharingHelperCls.shareDeviceWithTelus(localDeviceList);
		}
	}
}