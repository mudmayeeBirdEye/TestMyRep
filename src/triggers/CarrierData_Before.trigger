trigger CarrierData_Before on Carrier_Data__c (before Insert,Before update,after insert) {
	/*try{
		if(trigger.isInsert && trigger.isAfter){
		 //List<account> accList = [SELECT Id, Name, Account_Mobile_Number__c FROM Account WHERE RC_User_ID__c != null AND RC_Account_Number__c !=null AND recordTypeId !=null AND Name !=null AND recordType.Name='Customer Account'];
			set<String> setPhoneNumber = new set<String>();
			for(Carrier_Data__c carrierDataObj : Trigger.new) {
				if(!string.isBlank(carrierDataObj.Carrier_Wireless_Phone_Number__c)) {
					setPhoneNumber.add(carrierDataObj.Carrier_Wireless_Phone_Number__c);
				}
			}
			if(setPhoneNumber != null && setPhoneNumber.size()>0) {
				CarrierDataHelper.getAccountRecords(setPhoneNumber,Trigger.newmap.keySet());
			}
		}
		
	}catch(exception ex){ trigger.new.get(0).addError(ex.getMessage());}*/
	
	/**************************** MODIFIED BY VIREN ******************************/
	if(trigger.isInsert && trigger.isAfter){
		try {
			Set<Id> carrierDataIds = new Set<Id>();
			for(Carrier_Data__c carrierDataObj : trigger.new) {
				String originalPhoneNumber = carrierDataObj.Carrier_Wireless_Phone_Number__c;
				if(!String.isBlank(originalPhoneNumber)) {
					carrierDataIds.add(carrierDataObj.Id);
				}
			}
			CarrierDataHelper.getAccountRecords(carrierDataIds);
		}catch(exception ex){ trigger.new.get(0).addError(ex.getMessage());}
	}
	/**********************************************************/
}