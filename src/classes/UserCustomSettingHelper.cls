public with sharing class UserCustomSettingHelper {
	
	public static Boolean userRCSFName(String strName){
		Boolean boolResult;
		Map<string,RCSF_Sync__c> mapOfRCSF ;
		Map<string,RCPARTNER_Sync__c> mapOfRCPartner ;
		//Map<string,Sunil_Madan__c> mapOfSunil ;
		Map<string,Specific_User__c> mapOfSpecificUser ;
		Map<String,India_Team__c> mapIndiaTeam;
		
		//if(strName == UserRC.rcsfSyncUserObj.name){
		if( UserRC.compareUserName(strName)){
			mapOfRCSF = RCSF_Sync__c.getAll();
			if(mapOfRCSF != null){
			for(RCSF_Sync__c objRCSF : mapOfRCSF.Values()){
				if((objRCSF.Name == strName )||(objRCSF.Id__c == strName )){
					boolResult =true;
					system.debug('@@@@@'+mapOfRCSF);
				}
			}
			}
		//}else if(strName == UserRC.rcPartnerSyncUserObj.name){
		}else if(UserRC.compareRCPartnerUserName(strName)){
			mapOfRCPartner = RCPARTNER_Sync__c.getAll();
			for(RCPARTNER_Sync__c objRCSF : mapOfRCPartner.Values()){
				if((objRCSF.Name == strName )||(objRCSF.Id__c == strName )){
					boolResult =true;
				}
			}
		//}else if(strName == UserRC.sunilMadanUserObj.Name){
		}else if(UserRC.compareSpecificUserName(strName)){
			mapOfSpecificUser = Specific_User__c.getAll();
			for(Specific_User__c objRCSF : mapOfSpecificUser.Values()){
				if((objRCSF.Name == strName )||(objRCSF.Id__c == strName )){
					boolResult =true;
				}
			}
		//}else if(strName == UserRC.indiaTeamUserObj.name){
		}else if(UserRC.compareIndiaTeamUserName(strName)){
			mapIndiaTeam = India_Team__c.getAll();
			for(India_Team__c objRCSF : mapIndiaTeam.Values()){
				if((objRCSF.Name == strName )||(objRCSF.Id__c == strName )){
					boolResult =true;
				}
			}
		}
		if(boolResult == true)
			return true;
		else
			return false;	
	}
	
	public Static Set<string> getRCSFSync(String strNameOrIdOrEmail){
		Set<String> strSetNameOrId = new Set<String>();
		map<String,RCSF_Sync__c> mapRCUser = new map<String,RCSF_Sync__c>();
		map<String,RCPARTNER_Sync__c> mapRCPARTNER = new map<String,RCPARTNER_Sync__c>();
		map<String,Specific_User__c> mapRCUserSpecificUser = new map<String,Specific_User__c>();
		//if((strNameOrIdOrEmail == UserRC.rcsfSyncUserObj.name)||(strNameOrIdOrEmail == UserRC.rcsfSyncUserObj.Id__c)||(strNameOrIdOrEmail ==UserRC.rcsfSyncUserObj.Email__c)){
		if((UserRC.compareUserName(strNameOrIdOrEmail))||(UserRC.compareUserId(strNameOrIdOrEmail))||(UserRC.compareUserEmail(strNameOrIdOrEmail))){
			mapRCUser = RCSF_Sync__c.getAll();
			//if(strNameOrIdOrEmail == UserRC.rcsfSyncUserObj.name){
			if(UserRC.compareUserName(strNameOrIdOrEmail)){
				for(RCSF_Sync__c objRCSFSync:mapRCUser.values()){
					strSetNameOrId.add(objRCSFSync.Name);
				}
			//}else if(strNameOrIdOrEmail == UserRC.rcsfSyncUserObj.Id__c){
			}else if(UserRC.compareUserId(strNameOrIdOrEmail)){	
				
				for(RCSF_Sync__c objRCSFSync:mapRCUser.values()){
					strSetNameOrId.add(objRCSFSync.Id__c);
				}
			//}else if(strNameOrIdOrEmail ==UserRC.rcsfSyncUserObj.Email__c){
			}else if(UserRC.compareUserEmail(strNameOrIdOrEmail)){
				for(RCSF_Sync__c objRCSFSync:mapRCUser.values()){
					strSetNameOrId.add(objRCSFSync.Email__c);
				}
			}
		}else if((strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.name)||(strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.Id__c)||(strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.Email__c)){
			mapRCPARTNER = RCPARTNER_Sync__c.getAll();
			if(strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.name){
				for(RCPARTNER_Sync__c objRCSFPARTNERSync : mapRCPARTNER.values()){
					strSetNameOrId.add(objRCSFPARTNERSync.Name);
				}
			}else if(strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.Id__c){
				for(RCPARTNER_Sync__c objRCSFPARTNERSync : mapRCPARTNER.values()){
					strSetNameOrId.add(objRCSFPARTNERSync.Id__c);
				}
			}else if(strNameOrIdOrEmail == UserRC.rcPartnerSyncUserObj.Email__c){
				for(RCPARTNER_Sync__c objRCSFPARTNERSync : mapRCPARTNER.values()){
					strSetNameOrId.add(objRCSFPARTNERSync.Email__c);
				}
			}
		}else if((UserRC.compareSpecificUserName(strNameOrIdOrEmail))||(UserRC.compareSpecificUserId(strNameOrIdOrEmail))||(UserRC.compareSpecificUserEmail(strNameOrIdOrEmail))){
			mapRCUserSpecificUser = Specific_User__c.getAll();
			if(UserRC.compareSpecificUserName(strNameOrIdOrEmail)){
				for(Specific_User__c objSpecificUser:mapRCUserSpecificUser.values()){
					strSetNameOrId.add(objSpecificUser.Name);
				}
			}else if(UserRC.compareSpecificUserId(strNameOrIdOrEmail)){
				for(Specific_User__c objSpecificUser:mapRCUserSpecificUser.values()){
					strSetNameOrId.add(objSpecificUser.Id__c);
				}
			}else if(UserRC.compareSpecificUserEmail(strNameOrIdOrEmail)){
				for(Specific_User__c objSpecificUser:mapRCUserSpecificUser.values()){
					strSetNameOrId.add(objSpecificUser.Email__c);
				}
			}
		}
		return strSetNameOrId;
	}
}