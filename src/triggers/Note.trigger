/*************************************************
Trigger on Implementation object
After Insert & Update: Set Responded and Last Touched fields as needed.
/************************************************/

trigger Note on Note (after insert, after update) {
	Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
	
	if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {	
		set<Id> leadIdSet = new set<Id>();
		set<Id> opportunityIdSet = new set<Id>();
		for(Note noteObj : trigger.new) {
			if(!string.isBlank(noteObj.ParentId)) {
				if(String.valueof(noteObj.ParentId).startsWith('006')) {
					opportunityIdSet.add(noteObj.ParentId);
				} else if(String.valueof(noteObj.ParentId).startsWith('00Q')) {
					leadIdSet.add(noteObj.ParentId);
				}	
			}
		}
		
		map<Id,Opportunity> opportunityMap = new map<Id,Opportunity>();	
		map<Id,Lead> leadMap = new map<Id,Lead>();
		if(opportunityIdSet != null && opportunityIdSet.size()>0) {
			try {
				opportunityMap = new map<Id,Opportunity>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,
															Last_Touched_By__c from Opportunity where id IN :opportunityIdSet]);
			} catch(Exception ex) {}
		}
		if(leadIdSet != null && leadIdSet.size()>0) {
			try {
				leadMap = new map<Id,Lead>([SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c 
												from Lead where id IN: leadIdSet]);
			} catch(Exception ex) {}
		}
		
		List<Opportunity> oppListToUpd = new List<Opportunity>();
		List<Lead> leadListToUpd = new List<Lead>();
		set<Id> leadIdSetDupChk = new set<Id>();
		set<Id> oppIdSetDupChk = new set<Id>();
		
		for(Note noteObj : trigger.new) {
			if(opportunityMap != null && noteObj.ParentId != null && opportunityMap.containskey(noteObj.ParentId) 
				&& opportunityMap.get(noteObj.ParentId) != null && !oppIdSetDupChk.contains(noteObj.ParentId)) {
				Opportunity opp = opportunityMap.get(noteObj.ParentId);
				if(opp.Responded_Date__c == null && opp.Responded_By__c == null) {
					opp.Responded_Date__c = Datetime.now();
					opp.Responded_By__c = UserInfo.getUserId();
				}
				opp.Last_Touched_Date__c  = Datetime.now();
				opp.Last_Touched_By__c = UserInfo.getUserId();
				try {
					oppListToUpd.add(opp);
				} catch(Exception e) {noteObj.addError(e);}
				oppIdSetDupChk.add(noteObj.ParentId);	
			}
		
			if(leadMap != null && noteObj.ParentId != null && leadMap.containskey(noteObj.ParentId) && leadMap.get(noteObj.ParentId) != null 
					&& !leadIdSetDupChk.contains(noteObj.ParentId)) {
				Lead leadObj = 	leadMap.get(noteObj.ParentId);							
				if(leadObj.Responded_Date__c == null && leadObj.Responded_By__c == null) {
					leadObj.Responded_Date__c = Datetime.now();
					leadObj.Responded_By__c = UserInfo.getUserId();
				}
				leadObj.Last_Touched_Date__c  = Datetime.now();
				leadObj.Last_Touched_By__c = UserInfo.getUserId();
				try {
				   leadListToUpd.add(leadObj);
				}  catch(Exception e) { noteObj.addError(e);}
				leadIdSetDupChk.add(noteObj.ParentId);				
			}
		}
		
		try { 
			if(oppListToUpd != null && oppListToUpd.size()>0) {
				update oppListToUpd;
			}
			if(leadListToUpd != null && leadListToUpd.size()>0) {
				update leadListToUpd;
			}
		} catch(Exception ex) {} 
		
		
		/*for(Note noteObj : trigger.new){			
			for(Opportunity opp : [SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c from Opportunity where id =: noteObj.ParentId]){
				if(opp.Responded_Date__c==null && opp.Responded_By__c==null){
					opp.Responded_Date__c = Datetime.now();
					opp.Responded_By__c = UserInfo.getUserId();
				}
				opp.Last_Touched_Date__c  = Datetime.now();
				opp.Last_Touched_By__c = UserInfo.getUserId();
				try {
					update opp;
				} catch(Exception e) {noteObj.addError(e);}				
			}
			
			for(Lead lead : [SELECT id,Responded_Date__c,Responded_By__c,Last_Touched_Date__c,Last_Touched_By__c from Lead where id =: noteObj.ParentId]){								
				if(lead.Responded_Date__c==null && lead.Responded_By__c==null){
					lead.Responded_Date__c = Datetime.now();
					lead.Responded_By__c = UserInfo.getUserId();
				}
				lead.Last_Touched_Date__c  = Datetime.now();
				lead.Last_Touched_By__c = UserInfo.getUserId();
				try {
					update lead;
				}  catch(Exception e) {
					noteObj.addError(e);
				}			
			}		
		}*/
	}
	
	/*******************************************************************
	 * @Description.: updating the Account's lastTouchbySalesAgent     *
	 * @updatedBy...: India team                                       *
	 * @updateDate..: 19/03/2014                                       *
	 * @Case Number.: 02432238                                         *
	 *******************************************************************/
	/*********************************************Case:02432238 Start here *****************************************/
	try{
		User userObj = [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
		List<Account> lstParentAccount = new List<Account>();
		if(prof.Name.toLowerCase().contains('sales') && !prof.Name.toLowerCase().contains('engineer') ){
			for(Note noteObj: trigger.New){
				String id = noteObj.ParentId;
				String PrefixOfId = id.subString(0,3);
				if(PrefixOfId == '001'){
					lstParentAccount.add(new Account(id=noteObj.ParentId));
				}
			}
			AccountTriggerHelperExt.updateLastTouchedSalesPerson(lstParentAccount,userObj);
		}
	}catch(Exception Ex){
		system.debug('#### Error on line - '+ex.getLineNumber());
		system.debug('#### Error message - '+ex.getMessage());
	}
	/******************************************Case :02432238 End's here*************************************************/	
	
}