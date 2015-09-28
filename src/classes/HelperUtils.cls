public class HelperUtils {
	public HelperUtils() {
		
	}
	
	public static void updateCarrierDataRecordNew(List<Account> accountList) {
       List<Carrier_Data__c> updateCarrData = new List<Carrier_Data__c>();
       Set<string>  setAccMobNumber  = new Set<string>();
       Map<string,Account> MapMobNumAccount = new Map<string,Account>();
       for(Account objAcc :accountList) {
			String originalPhoneNumber = objAcc.Account_Mobile_Number__c;
 			if(!String.isBlank(originalPhoneNumber)) {
 				String formatPhoneWithCode = formatPhoneNumberWithCode(originalPhoneNumber);
 				String formatPhoneWithoutCode = formatPhoneNumberWithoutCode(originalPhoneNumber);
           		setAccMobNumber.add(formatPhoneWithCode.trim());
           		setAccMobNumber.add(formatPhoneWithoutCode.trim());
           		MapMobNumAccount.put(formatPhoneWithCode.trim(),objAcc);
           		MapMobNumAccount.put(formatPhoneWithoutCode.trim(),objAcc);
       		}
       }
       System.Debug('>>22>>'+setAccMobNumber);
       if(!setAccMobNumber.isEmpty()) {
          	List<Carrier_Data__c>  lstCarrData = [SELECT Id,Carrier_Wireless_Phone_Number__c FROM Carrier_Data__c 
                                 					WHERE  Carrier_Wireless_Phone_Number__c != NULL AND Carrier_Wireless_Phone_Number__c IN:setAccMobNumber order by lastmodifiedDate];
          	for(Carrier_Data__c objCarrData : lstCarrData) {
          		String originalPhoneNumber = objCarrData.Carrier_Wireless_Phone_Number__c;
          		String formatPhoneWithCode = formatPhoneNumberWithCode(originalPhoneNumber);
 				String formatPhoneWithoutCode = formatPhoneNumberWithoutCode(originalPhoneNumber);
 				
 				Account accountObj = MapMobNumAccount.get(formatPhoneWithCode);
          		if(accountObj != null) {
          			objCarrData.Account__c = accountObj.Id;
          			updateCarrData.add(objCarrData);
          		} else {
          			accountObj = MapMobNumAccount.get(formatPhoneWithoutCode);
          			if(accountObj != null) {
	          			objCarrData.Account__c = accountObj.Id;
	          			updateCarrData.add(objCarrData);
	          		}
          		}
       		}
          	if(!updateCarrData.isEmpty()) {
            	update updateCarrData;
          	}
        }
  	}
    private static String formatPhoneNumberWithCode(String originalPhoneNumber) {
		return (originalPhoneNumber.length() == 10 ? '1' + originalPhoneNumber : originalPhoneNumber);
	}
	private static String formatPhoneNumberWithoutCode(String originalPhoneNumber) {
		return (originalPhoneNumber.length() == 11 ? originalPhoneNumber.substring(1,originalPhoneNumber.length()) : originalPhoneNumber);
	}
}