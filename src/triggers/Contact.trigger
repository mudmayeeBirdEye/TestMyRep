/*************************************************
Trigger on Contact object
Before Insert: Set indexed email and phone fields.
Before Update: Update indexed email and phone fields. 
/************************************************/ 

trigger Contact on Contact (before insert, before update) {
	if(TriggerHandler.BY_PASS_CONTACT_ON_INSERT || TriggerHandler.BY_PASS_CONTACT_ON_UPDATE || TriggerHandler.BY_PASS_CONTACT_ON_BEFORE){
		System.debug('### RETURNED FROM CONTACT BEFORE TRG ###');    
		return;
	} else {
		TriggerHandler.BY_PASS_CONTACT_ON_BEFORE = true;
		System.debug('### STILL CONTINUE FROM CONTACT BEFORE TRG ###');    
	}
    if(trigger.isInsert){   
    	/************* Contact Owner Assign to RCSF Sync ***********/ 
    	set<Id> OwnerIDSet = new set<Id>();   
    	for(Contact contactObj: trigger.new) {
    		if(contactObj.OwnerId != null) {
    			OwnerIDSet.add(contactObj.OwnerId);
    		}	
    	}
    	     
    	//No_of_Employee Range Mapping
		ContactTriggerHelper.validateEmployeeRangeForNumericValues(Trigger.new);
		ContactTriggerHelper.getCheckForBadValue(Trigger.new);
		
		//Field Update in Contact on basis of Account Status.
		ContactTriggerHelper.updateContactOnAccount(Trigger.new);	
		
		//Assign Campaign
    	ContactLeadAssignmentHelper.assignCampaignToContact(trigger.new);
    	
    	map<Id,User> mapUserOwner = new map<Id,User>([SELECT Id, IsActive FROM USer where Id IN : OwnerIDSet]);
    	
    	for(Contact contactObj: trigger.new) {    
    		System.debug('>>>>###>>');  	
    		if(mapUserOwner != null && contactObj.OwnerId != null && mapUserOwner.get(contactObj.OwnerId) != null && 
    			mapUserOwner.get(contactObj.OwnerId).IsActive == false) {
    			System.debug('>>>>###>>');	
    			contactObj.OwnerId = '005800000036sJJ';	// RCSF Sync
    			System.debug('>>>>###>>');	
    		}
    	}
    	
    	/********************************************************/
    	
        /*Added for chking duplicate mail id on Account*/
        chkContactOnAccount.areContactMailAllowed(Trigger.new);
        for(Contact contactObj: trigger.new){                   
            contactObj.indexedEmail__c = contactObj.Email;
            contactObj.indexedPhone__c = contactObj.Phone; 
         }
        // AccountCleanUpProcess.cleanUpCurrentContacts(trigger.new, null);
        Set<Id> accountIds = new Set<Id>();
        for(Contact contactObj: trigger.new){                   
            if(contactObj.Email != 'fake@email.com' && contactObj.Email != 'fake@fake.com') {
            	accountIds.add(contactObj.AccountId);
            }
         }
        if(accountIds.size() != 0) {
        	Map<Id, Boolean> accountToNullStatus = new Map<Id, Boolean>();
			for(Account accountObj : [SELECT Id,Partner_ID__c FROM Account WHERE Id IN: accountIds]) {
				accountToNullStatus.put(accountObj.Id, false);
				if(accountObj.Partner_ID__c != null) {
					accountToNullStatus.put(accountObj.Id, true);
				}
			}
			if(accountToNullStatus.size() != 0) {
				for(Contact contactObj: trigger.new){ 
					if(accountToNullStatus.get(contactObj.AccountId) == true) {
						contactObj.marketingSuspend__c = true;
					}
				} 
			}
        }
        
     }

    if(trigger.isUpdate){
        /*Added for chking duplicate mail id on Account*/
        //chkContactOnAccount.areContactMailAllowed(Trigger.new);
        chkContactOnAccount.areContactMailAllowedUpdate(Trigger.new, Trigger.oldMap);       
        
        List<Contact> numberOfEmpContactUpdatedList = new List<Contact>(); 
        
        for(Integer i=0; i<trigger.new.size(); i++){
            if(trigger.new[i].Phone != trigger.old[i].Phone){
                trigger.new[i].indexedPhone__c = trigger.new[i].Phone; 
            }
            
            if(trigger.new[i].email != trigger.old[i].email){
                trigger.new[i].indexedEmail__c = trigger.new[i].email; 
            }
            
            if(trigger.new[i].NumberOfEmployees__c!=null && trigger.new[i].NumberOfEmployees__c != trigger.old[i].NumberOfEmployees__c){
            	numberOfEmpContactUpdatedList.add(trigger.new[i]);
            }
        }
        
        //No. of Employee mapping.
        if(numberOfEmpContactUpdatedList!=null && numberOfEmpContactUpdatedList.size() > 0){
        	ContactTriggerHelper.validateEmployeeRangeForNumericValues(numberOfEmpContactUpdatedList);
			ContactTriggerHelper.getCheckForBadValue(numberOfEmpContactUpdatedList);
        }
        
        // AccountCleanUpProcess.cleanUpCurrentContacts(trigger.new, trigger.old);
        
        List<Contact> currentContacts = new List<Contact>();
		Set<Id> accountIds = new Set<Id>();
		for(Integer i = 0; i < trigger.new.size(); i++) {
			if(trigger.new[i].AccountId != trigger.old[i].AccountId) {
				currentContacts.add(trigger.new[i]);
				Contact contactObj = trigger.new[i];
				if(contactObj.Email != 'fake@email.com' && contactObj.Email != 'fake@fake.com') {
	            	accountIds.add(contactObj.AccountId);
	            }
			}
		}
        if(accountIds.size() != 0) {
        	Map<Id, Boolean> accountToNullStatus = new Map<Id, Boolean>();
			for(Account accountObj : [SELECT Id,Partner_ID__c FROM Account WHERE Id IN: accountIds]) {
				accountToNullStatus.put(accountObj.Id, false);
				if(accountObj.Partner_ID__c != null) {
					accountToNullStatus.put(accountObj.Id, true);
				}
			}
			if(accountToNullStatus.size() != 0) {
				for(Contact contactObj: currentContacts){ 
					if(accountToNullStatus.get(contactObj.AccountId) == true) {
						contactObj.marketingSuspend__c = true;
					}
				} 
			}
        }
        /*************** MARKETO DUPLICATE CONTACT ***********************/
        try {
        	Set<Id> ownerIds = new Set<Id>();
	        for(Contact contactObj : trigger.new){
	            ownerIds.add(contactObj.OwnerId);
	        }
	        ownerIds.add(UserInfo.getUserId());
	        Map<Id,User> userMap = new Map<Id, User>([SELECT Name, Profile.Name, Email, Manager.Email, Phone,Manager.Username, IsActive, ManagerId, Mkto_Reply_Email__c
	                                                                 From User WHERE Id IN: ownerIds]);
            if ('Marketo Integration Profile'.equalsIgnoreCase(userMap.get(UserInfo.getUserId()).Profile.Name)) {
	        	/******************/
            	//As per new case "02410144"
	        	/*Map<Id, OpportunityContactRole> oppContactMap = new Map<Id, OpportunityContactRole>();
	        	for(OpportunityContactRole oppContactRole : [SELECT Id, ContactId, OpportunityId, Opportunity.Lead_Merged_Counter__c ,
	        														Opportunity.StageName FROM OpportunityContactRole 
	        														WHERE ContactId IN: trigger.newMap.keySet() ORDER BY LastModifiedDate DESC LIMIT 1]) {
	        		oppContactMap.put(oppContactRole.ContactId, oppContactRole);
	        	}
	        	
        		Date firstDayOfMonth = System.today().toStartOfMonth();
				Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
	        	
	        	List<Opportunity> newOpps = new List<Opportunity>();
	        	List<Opportunity> updateOpps = new List<Opportunity>();
	        	List<OpportunityContactRole> newOppContactRoles = new List<OpportunityContactRole>();
	        	Map<Id, Opportunity> contactToOppMap = new Map<Id, Opportunity>();*/
	        	/******************/
            	//As per new case "02410144"
    			for(Contact contactObj : trigger.new) {
    				if(contactObj.Marketo_Duplicate_Lead__c == true) {
    					contactObj.Lead_Merged_Date__c = System.today();
                    	contactObj.Lead_Merged_Counter__c = (contactObj.Lead_Merged_Counter__c == NULL)? 1:(contactObj.Lead_Merged_Counter__c + 1);
	    				//As per new case "02410144" of Re-new Code
	    				/*if( oppContactMap.get(contactObj.Id) == null || oppContactMap.get(contactObj.Id).Opportunity.StageName.indexOf('8. Closed Won') != -1) {
	    					Opportunity oppObj = new Opportunity(Marketo_Duplicate_Lead__c=true, Lead_Merged_Counter__c = 1, Lead_Merged_Date__c = system.today(),
	    					leadSource = contactObj.LeadSource,Number_of_Employees__c = contactObj.NumberOfEmployees__c, 
	    					AccountId=contactObj.AccountId, StageName='.5 Re-New', Name='Initial Lead Added to Contact - ' + ((contactObj.FirstName == null || contactObj.FirstName == '')?' ':contactObj.FirstName) + ' ' + ((contactObj.LastName == null || contactObj.LastName == '')?' ':contactObj.LastName), CloseDate=lastDayOfMonth);
	    					newOpps.add(oppObj);
	    					contactToOppMap.put(contactObj.Id, oppObj);
	    					// newOppContactRoles.add(new OpportunityContactRole(ContactId=contactObj.Id, OpportunityId=oppObj.Id));
	    				} else {
	    					Opportunity oppObj = oppContactMap.get(contactObj.Id).Opportunity;
	    					if(oppObj.StageName.indexOf('0. Downgraded') != -1) {
	    						oppObj.StageName = '.5 Re-New';
	    						oppObj.Marketo_Duplicate_Lead__c=true;
	    						oppObj.Lead_Merged_Date__c = system.today();
	    						oppObj.LeadSource = (String.isBlank(oppObj.LeadSource)?contactObj.LeadSource:oppObj.LeadSource);
								oppObj.Number_of_Employees__c = (oppObj.Number_of_Employees__c!=null? oppObj.Number_of_Employees__c:contactObj.NumberOfEmployees__c); 
    	 						oppObj.Lead_Merged_Counter__c = oppContactMap.get(contactObj.Id).Opportunity.Lead_Merged_Counter__c == null ? 1 : (oppContactMap.get(contactObj.Id).Opportunity.Lead_Merged_Counter__c + 1);
	    						updateOpps.add(oppObj);
	    					}
	    				}*/
	    				//End As per new case "02410144" of Re-new Code
    				}
    			}
    			//As per new case "02410144" of Re-new Code
	    		/*if(!newOpps.isEmpty()) {
	    			try {
	                	TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
                    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
                    	//TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
                 		insert newOpps;
                 		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
                    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
	    			} catch(Exception e ) { for(Contact obj : trigger.new ){obj.addError('This user does not have access privilege to Employee object.');} }
	    			for(Id conId : contactToOppMap.keySet()) {
	    				Opportunity oppObj = contactToOppMap.get(conId);
	    				newOppContactRoles.add(new OpportunityContactRole(ContactId=conId, OpportunityId=oppObj.Id));
	    			}
	    		}
	    		if(!updateOpps.isEmpty()) {
	    			try {
	    				TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
                    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
                    	//TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
	    				update updateOpps;
	    				TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
                    	TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = false;
	    			} catch(Exception e ) {}
	    		}
	    		if(!newOppContactRoles.isEmpty()) {
	    			try {
	    				insert newOppContactRoles;
	    			} catch(Exception e ) {}
	    		}*/
	    		//End As per new case "02410144" of Re-new Code
	    		ContactLeadAssignmentHelper.assignCampaignToContact(trigger.new);
                ContactLeadAssignmentHelper.initialContacts(trigger.new, userMap);
                for(Contact contactObj : trigger.new) {
                	contactObj.Marketo_Duplicate_Lead__c = false;
                }
            } else {            	
		        //Update Most Recent Campaign
		        ContactLeadAssignmentHelper.updateMostRecentCampaign(Trigger.New, Trigger.oldMap); 
            }
        } catch(Exception e) {trigger.new[0].addError(e.getStackTraceString());}
        /**************** MARKETO DUPLICATE CONTACT **********************/
    }
    /*********************************** RESET CAMPAIGN FOR EMPTY BMID AND DEFAULT CAMPAIGN ******************************************/
    try {
    	ContactLeadAssignmentHelper.validateCampaign(trigger.new);  
    } catch(Exception ex) {}
	/*********************************************************************************************************************************/     
}