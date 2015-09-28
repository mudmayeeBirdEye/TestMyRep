trigger Contact_After on Contact (after insert, after update) {
    if(TriggerHandler.BY_PASS_CONTACT_ON_INSERT || TriggerHandler.BY_PASS_CONTACT_ON_UPDATE || TriggerHandler.BY_PASS_CONTACT_ON_AFTER){
		System.debug('### RETURNED FROM CONTACT AFTER TRG ###'); 
		return;
	} else {   
		TriggerHandler.BY_PASS_CONTACT_ON_AFTER = true;
		System.debug('### STILL CONTINUE FROM CONTACT AFTER TRG ###');
	}
    Map<String, String> mobLeadSources 
        = new Map<String, String>{'m' => 'm', 'iphone' => 'iphone', 
                                  'bb' => 'bb', 'android' => 'android'};
    
    /*
    For every Contact being inserted
    */
    
    Set<Id> accountIdSet = new Set<Id>();
   	for(Contact contactobj : trigger.new){
   		if(!String.isBlank(contactObj.AccountId)) {
	   		accountIdSet.add(contactObj.AccountId);
   		}
 	} 
   	Map<Id,Account> parentAccountMap = new Map<Id,Account>([SELECT SignupType__c, SignupPlatform__c, Name, RC_Account_Status__c,
                              									   RC_Account_Number__c,RC_User_ID__c,RC_Tier__c,RC_Brand__c,RC_Service_name__c 
               												FROM Account WHERE Id IN :accountIdSet AND createdDate = TODAY]);
    if(trigger.isInsert){
	   try { 
	   		List<CampaignMember> campaignMemberList = new List<CampaignMember>();
	       	for(Contact contactobj : trigger.new){
	       		
	       		//Campaign Member Assosiation
	       		if(contactObj.Primary_Campaign__c!=null){
	       			CampaignMember campMemberObj = new CampaignMember(CampaignId=contactObj.Primary_Campaign__c,contactId=contactObj.Id);
	       			campaignMemberList.add(campMemberObj);
	       		}
	       		
	       		// VARIABLE DECLARATION
	       		Account accountObj = (!String.isBlank(contactObj.AccountId) ? parentAccountMap.get(contactObj.accountId) : null);
	       		String signupType;
	       		String accountStatus; 
	       		String signupPlatform;
	       		if(accountObj != null) {
	       			signupType = accountObj.SignupType__c;
	       			accountStatus = accountObj.RC_Account_Status__c;
	       			signupPlatform = accountObj.SignupPlatform__c;
	       		}
	       		
	         	if(parentAccountMap != null && accountObj != null && signupType != null) {
					//create a lead and populate values from current Contact 
	               	Lead newLead = new Lead();
					newLead.Phone = contactobj.Phone; 
					newLead.LastName = contactobj.LastName; 
					newLead.FirstName = contactobj.FirstName; 
					newLead.Email = contactobj.Email; 
					newLead.Company  =  accountObj.Name;                          
					newLead.Status = '1. New'; 
					//Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
					newLead.Account_Status__c = accountStatus;
					newLead.Account_Number__c = accountObj.RC_Account_Number__c;
					newLead.User_ID__c = accountObj.RC_User_ID__c;
					newLead.Lead_Tier_Name__c = accountObj.RC_Tier__c;
					newLead.RC_Service_name__c = accountObj.RC_Service_name__c;
					newLead.Lead_Brand_Name__c = accountObj.RC_Brand__c;
					// Trial Web leads
					if((String.isBlank(signupPlatform) || signupPlatform.toUpperCase()=='WEB') 
						&& (signupType.toUpperCase().trim().equals('TRIAL_30NOCC'))) {
							newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
						if(!String.isBlank(accountStatus) && accountStatus.toUpperCase() != 'DWH SYNC PENDING' 
							&& (accountStatus.toUpperCase()).trim().contains('TRIAL') ) {
							insert newLead;
						}
						System.debug('\n\n\n\nlead source is WEB');     
						// Trial                         
					} else if(signupPlatform != null && 
								mobLeadSources.get(signupPlatform) != null
						&& ((signupType.toUpperCase().trim().equals('TRIAL_30NOCC') || signupType.toUpperCase().trim().equals('TRIAL_NOCC')))){
							//Map mobLeadSources has these values (m, iphone, bb, android)
                            //if SignupPlatform needs to have any other value matched, it should be added to 
                            //mobLeadSources map as key & value
							newLead.LeadSource = 'TRIAL 30d-NO-CC-MOB';
							//To check if Account status is DWH SYNC PENDING,then don't create new Lead 
                            //To check if Account status Contains Trial,then create new Lead
						if(!String.isBlank(accountStatus) && 
							accountStatus.toUpperCase() != 'DWH SYNC PENDING' && 
								(accountStatus.toUpperCase()).trim().contains('TRIAL') ) {
							insert newLead;
						}
						System.debug('\n\n\n\nlead source is MOB');                             
					}
					else {  
						if(!String.isBlank(accountStatus) && accountStatus.toUpperCase() == 'TRIAL 30 NO-CC' && signupPlatform == null){
							//create a lead and populate values from current Contact 
							newLead.Phone = contactobj.Phone; 
							newLead.LastName = contactobj.LastName; 
							newLead.FirstName = contactobj.FirstName; 
							newLead.Email = contactobj.Email; 
							newLead.Company  =  accountObj.Name;
							//Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
							newLead.Account_Status__c = accountStatus;
							newLead.Account_Number__c = accountObj.RC_Account_Number__c;
							newLead.User_ID__c = accountObj.RC_User_ID__c;
							newLead.Lead_Tier_Name__c = accountObj.RC_Tier__c;
							newLead.RC_Service_name__c = accountObj.RC_Service_name__c;
							newLead.Lead_Brand_Name__c = accountObj.RC_Brand__c; 
							newLead.Status = 'Open - Not Contacted';
							newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
							System.debug('\n\n\n\nlead source is WEB');
							insert newLead;
						}                       
				    }  
	            }
	        }
	        //Campaign Member Assosiation
	        if(campaignMemberList!=null && campaignMemberList.size() > 0){
	        	insert campaignMemberList;
	        }
	        //get Account information for this contact
	    } catch(System.Exception e){ System.debug(' #### EXCEPTION OCCURED IN TRIAL LEADS ### ' + e.getMessage());}    
	    //bulk trigger update loop       
		AccountCleanUpProcess.cleanUpContacts(trigger.newMap);  
	}  
     
    /*if(trigger.isInsert){
               for(Integer i=0; i<trigger.size; i++) {
           //Get the account id of this contact
         try{ 
           for(Account parentAccount:[Select SignupType__c, SignupPlatform__c, Name, RC_Account_Status__c,
                              RC_Account_Number__c,RC_User_ID__c,RC_Tier__c,RC_Brand__c,RC_Service_name__c 
               From Account where Id =:trigger.new[i].AccountId AND createdDate=TODAY limit 1]) {
     
               //if fetched account is not null, just in case
               if(parentAccount != null ){
               		// modified the condition on June 13, 2011    
                    if( parentAccount.SignupType__c !=null){                                                                                                            
                     //  if( parentAccount.SignupType__c.toUpperCase().trim().contains('TRIAL_')){
                       	
                       /*	if( parentAccount.SignupType__c !=null){                                                                                                            
                       if( parentAccount.SignupType__c.toUpperCase()=='TRIAL 30D NO CC' 
						|| parentAccount.SignupType__c.toUpperCase()=='TRIAL_NOCC' ){ */
                        
                           //create a lead and populate values from current Contact 
                           /*Lead newLead = new Lead();
                           newLead.Phone = trigger.new[i].Phone; 
                           newLead.LastName = trigger.new[i].LastName; 
                           newLead.FirstName = trigger.new[i].FirstName; 
                           newLead.Email = trigger.new[i].Email; 
                           newLead.Company  =  parentAccount.Name;                          
                           newLead.Status = '1. New'; 
                           
                            //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
                            newLead.Account_Status__c = parentAccount.RC_Account_Status__c;
                            newLead.Account_Number__c = parentAccount.RC_Account_Number__c;
                            newLead.User_ID__c = parentAccount.RC_User_ID__c;
                            newLead.Lead_Tier_Name__c = parentAccount.RC_Tier__c;
                            newLead.RC_Service_name__c = parentAccount.RC_Service_name__c;
                            newLead.Lead_Brand_Name__c = parentAccount.RC_Brand__c;
                                
                     		if(parentAccount.SignupPlatform__c == null 
                                || parentAccount.SignupPlatform__c.toUpperCase()=='WEB' 
                                && ( parentAccount.SignupType__c.toUpperCase().trim().equals('TRIAL_30NOCC'))){
                                newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
                                if(parentAccount.RC_Account_Status__c != null && parentAccount.RC_Account_Status__c.toUpperCase() != 'DWH SYNC PENDING' 
                                && (parentAccount.RC_Account_Status__c.toUpperCase()).trim().contains('TRIAL') ) {
                                    insert newLead;
                                }
                                System.debug('\n\n\n\nlead source is WEB');                             
                            } else if(parentAccount.SignupPlatform__c != null && mobLeadSources.get(parentAccount.SignupPlatform__c) != null
                                && ( parentAccount.SignupType__c.toUpperCase().trim().equals('TRIAL_30NOCC') 
                                ||  parentAccount.SignupType__c.toUpperCase().trim().equals('TRIAL_NOCC') )){
                
                                //Map mobLeadSources has these values (m, iphone, bb, android)
                                //if SignupPlatform needs to have any other value matched, it should be added to 
                                //mobLeadSources map as key & value
                                newLead.LeadSource = 'TRIAL 30d-NO-CC-MOB';
                                //To check if Account status is DWH SYNC PENDING,then don't create new Lead 
                                //To check if Account status Contains Trial,then create new Lead
                                if(parentAccount.RC_Account_Status__c != null && parentAccount.RC_Account_Status__c.toUpperCase() != 'DWH SYNC PENDING' && (parentAccount.RC_Account_Status__c.toUpperCase()).trim().contains('TRIAL') ) {
                                    insert newLead;
                                }
                                System.debug('\n\n\n\nlead source is MOB');                             
                            }
							// insert newLead;
                       //}
                   
                   } else {  //if account signup type is null
                        //IF the account status = Trial 30 no-CC
                        if(null != parentAccount.RC_Account_Status__c
                        	&& parentAccount.RC_Account_Status__c.toUpperCase() == 'TRIAL 30 NO-CC' 
                            	&& parentAccount.SignupPlatform__c == null){

                           //create a lead and populate values from current Contact 
                           Lead newLead = new Lead();
                           newLead.Phone = trigger.new[i].Phone; 
                           newLead.LastName = trigger.new[i].LastName; 
                           newLead.FirstName = trigger.new[i].FirstName; 
                           newLead.Email = trigger.new[i].Email; 
                           newLead.Company  =  parentAccount.Name;
                           
                           //Populate additional field as mentioned in E-mail on 6/2/2011,while creating Lead
                            newLead.Account_Status__c = parentAccount.RC_Account_Status__c;
                            newLead.Account_Number__c = parentAccount.RC_Account_Number__c;
                            newLead.User_ID__c = parentAccount.RC_User_ID__c;
                            newLead.Lead_Tier_Name__c = parentAccount.RC_Tier__c;
                            newLead.RC_Service_name__c = parentAccount.RC_Service_name__c;
                            newLead.Lead_Brand_Name__c = parentAccount.RC_Brand__c; 
                                                                       
                           newLead.Status = 'Open - Not Contacted';
                            
                           newLead.LeadSource = 'TRIAL 30d-NO-CC-WEB';
                           System.debug('\n\n\n\nlead source is WEB');
                               
                           insert newLead;
                        }                       
                   }  
                   
               }//if fetched account is not null
               
           }//get Account information for this contact
         }     catch(System.QueryException e){}          
       }//bulk trigger update loop 
              AccountCleanUpProcess.cleanUpContacts(trigger.newMap);  
    }//if isInsert trigger*/
    
    /*
    For every Contact being updated
    */
    if(trigger.isUpdate){ 
    	
    	//Campaign Member Assosiation    	
    	Set<String> campaignIdSet = new Set<String>();
    	
    	Map<Id, Contact> changedMap = new Map<Id, Contact>();
    	for(Id contactId : trigger.newMap.keySet()) {
    		if(trigger.newMap.get(contactId).accountId != trigger.oldMap.get(contactId).accountId) {
    			changedMap.put(contactId, trigger.newMap.get(contactId));
    		}
    		
    		//Campaign Member Assosiation
    		if(trigger.newMap.get(contactId).Most_Recent_Campaign__c!=null && trigger.newMap.get(contactId).Most_Recent_Campaign__c != trigger.oldMap.get(contactId).Most_Recent_Campaign__c){
    			campaignIdSet.add(string.valueOf(trigger.newMap.get(contactId).Most_Recent_Campaign__c).subString(0,15));
    		}
    	}
    	
    	//Campaign Member Assosiation
    	if(campaignIdSet!=null && campaignIdSet.size() > 0){
			map<Id,map<Id,boolean>> campaignLeadRelationMap = new map<Id,map<Id,boolean>>(); 
    		for(Campaign  campObj : [select id,(SELECT CampaignId, ContactId From CampaignMembers 
					WHERE contactId IN: trigger.newMap.keySet()) from Campaign where Id in : campaignIdSet AND IsActive=true]){
				if(campObj.CampaignMembers!=null && campObj.CampaignMembers.size() > 0){
					for(CampaignMember campMemberObj : campObj.CampaignMembers){
						if(campaignLeadRelationMap.get(campObj.Id)!=null){
							map<Id,boolean> tempMap = campaignLeadRelationMap.get(campObj.Id);
							tempMap.put(campMemberObj.ContactId,true);
							campaignLeadRelationMap.put(campObj.Id,tempMap);
						}else{
							map<id,boolean> tempMap = new map<id,boolean>();
							tempMap.put(campMemberObj.ContactId,true);
							campaignLeadRelationMap.put(campObj.Id,tempMap);							
						}
					}
				}else{
					campaignLeadRelationMap.put(campObj.Id,new Map<id,boolean>());
				}		
			}
			List<CampaignMember> campaignMemberNewList = new List<CampaignMember>();
			for(Contact newContactObj: trigger.new) {
				if(newContactObj.Most_Recent_Campaign__c!=null && newContactObj.Most_Recent_Campaign__c != trigger.oldMap.get(newContactObj.Id).Most_Recent_Campaign__c){
					if(campaignLeadRelationMap!=null && campaignLeadRelationMap.get(newContactObj.Most_Recent_Campaign__c)!=null){
						if(campaignLeadRelationMap.get(newContactObj.Most_Recent_Campaign__c).get(newContactObj.Id)!=null){
							//CampaignMember already exists for this CampaignId and ContactId combination.
						}else{
							//Create new CampaignMember for this CampaignId and ContactId combination.
							CampaignMember campMemberObj = new CampaignMember(campaignId=newContactObj.Most_Recent_Campaign__c, contactId=newContactObj.Id);
							campaignMemberNewList.add(campMemberObj);
						}
					}
				}
			}
			if(campaignMemberNewList!=null && campaignMemberNewList.size() > 0){
				try {					
					insert campaignMemberNewList;					
				}catch(Exception e) {}
			}
    	}
    	
    	if(changedMap.size() != 0) {
    		AccountCleanUpProcess.cleanUpContacts(changedMap);
    	} 
    }
    
    try {
   		Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
    	Map<ID,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();
    	Map<String, Certification__c> mcs = Certification__c.getAll();
    	Set<Id> accountId = new Set<Id>();
    	for(Contact contactObj : trigger.new) {
    		accountId.add(contactObj.AccountId);
    		//system.debug('@123@'+contactObj.AccountId);
    		//system.debug('###45&&&'+accountId);
    	}
    	 /*Map<Id,Account> accountMap = new Map<Id, Account>([SELECT id,Preferred_Language__c,Most_Recent_Implementation_Contact__c,Technical_Certification__c FROM Account WHERE Id IN: accountId 
                                                           and RecordType.Name = 'Partner Account']);*/
        Map<Id,Account> accountMap = new Map<Id, Account>([SELECT id,RecordType.Name,Preferred_Language__c,Most_Recent_Implementation_Contact__c,Technical_Certification__c
                                                            FROM Account WHERE Id IN: accountId]);
                                                           
       Map<Id,Contact> mapcontid = new Map<Id,Contact>([SELECT Id, Name from Contact where AccountId IN :accountId order by lastModifiedDate desc]); 
                                                           
        //system.debug('-------***'+accountMap);                                             
        Set<Account> accLstToUpd = new Set<Account>();
         
        for(Contact contactObj : trigger.new) {
            Contact contactObjOld = Trigger.isUpdate == true ?  Trigger.oldMap.get(contactObj.id) : null;
            //Map<Id,Contact> mapcontid = new Map<Id,Contact>([SELECT Id,name,(Select Id, AccountId, ContactId, Role, IsPrimary From AccountContactRoles where isPrimary=true ) from Contact where id IN :accountId]); 
            if(accountMap.get(contactObj.AccountId)!= null){
                Account accObjToUpd = accountMap.get(contactObj.AccountId);
                system.debug('contactObj.Preferred_Language__c === '+contactObj.Preferred_Language__c);
                //String primarycont = mapcontid.get(contactObj.AccountId).Preferred_Language__c;
                boolean isLastModifiedDate = true;
                boolean isAccountUpdated = false;
                if(!mapcontid.isEmpty() && mapcontid.get(contactObj.id) != null && mapcontid.get(contactObj.id).AccountContactRoles.size()>0){
                    for(AccountContactRole accConRole : mapcontid.get(contactObj.id).AccountContactRoles){
                        if(isLastModifiedDate && accConRole.isPrimary 
                            && accConRole.ContactId == contactObj.Id
                            && (accConRole.ContactId != accObjToUpd.Most_Recent_Implementation_Contact__c 
                                || (accObjToUpd.Preferred_Language__c !=  contactObj.Preferred_Language__c
                                    && accConRole.ContactId == accObjToUpd.Most_Recent_Implementation_Contact__c)
                                )
                            ){
                            accObjToUpd.Preferred_Language__c =  contactObj.Preferred_Language__c;
                            accObjToUpd.Most_Recent_Implementation_Contact__c =  contactObj.id;
                            isLastModifiedDate = false;
                            isAccountUpdated = true;
                            system.debug('accObjToUpd.Preferred_Language__c+++++++'+accObjToUpd.Preferred_Language__c);
                        }                   
                    }
                    
                } else if(isLastModifiedDate 
                            && (accObjToUpd.Most_Recent_Implementation_Contact__c != contactObj.id 
                            || (accObjToUpd.Most_Recent_Implementation_Contact__c == contactObj.id
                                && accObjToUpd.Preferred_Language__c !=  contactObj.Preferred_Language__c)
                                )
                            ){
                            accObjToUpd.Preferred_Language__c =  contactObj.Preferred_Language__c;
                            accObjToUpd.Most_Recent_Implementation_Contact__c =  contactObj.id;
                            isLastModifiedDate = false;
                            isAccountUpdated = true;
                        }
                
                //accObjToUpd.Preferred_Language__c =  mapcontid.get(contactObj.AccountId).Preferred_Language__c; 
                system.debug('accObjToUpd.Preferred_Language__c === '+accObjToUpd.Preferred_Language__c);
                if(!String.isBlank(contactObj.Technical_Certification__c) && accObjToUpd.RecordType.Name == 'Partner Account' &&
                    (contactObjOld == null || contactObj.Technical_Certification__c != contactObjOld.Technical_Certification__c)) {
                    
                    if(accountMap != null && contactObj.AccountId != null) {
                        if(accountMap.get(contactObj.AccountId).Technical_Certification__c == null 
                        || accountMap.get(contactObj.AccountId).Technical_Certification__c =='None' 
                        
                         && accountMap.get(contactObj.AccountId)!= null){
                            accObjToUpd.Technical_Certification__c = contactObj.Technical_Certification__c;
                            //system.debug('@@@@'+accObjToUpd.Technical_Certification__c);
                            //system.debug('*********'+contactObj.Technical_Certification__c);
                            //accLstToUpd.add(accObjToUpd); 
                            isAccountUpdated = true;
                            //system.debug('@2345@'+accLstToUpd);   
                         
                    } else if(accountMap != null && accountMap.get(contactObj.AccountId).Technical_Certification__c != null) {
                            string accountTechCerti = accountMap.get(contactObj.AccountId).Technical_Certification__c;
                            string contactTechCerti = contactObj.Technical_Certification__c;
                            Decimal accountTechCertiRank = mcs.get(accountTechCerti).Rank_in_number__c;
                            system.debug('######'+accountTechCertiRank);
                            Decimal contactTechCertiRank = mcs.get(contactTechCerti).Rank_in_number__c;
                            if(accountTechCertiRank > contactTechCertiRank) {
                                accObjToUpd.Technical_Certification__c = contactObj.Technical_Certification__c;
                                //system.debug('12345'+accObjToUpd.Technical_Certification__c);
                                isAccountUpdated = true;
                                //accLstToUpd.add(accObjToUpd);
                            }
                        }
                    }
                        
                }
                if(isAccountUpdated){
                    accLstToUpd.add(accObjToUpd);
                }
            }
        }
        if(accLstToUpd != null && accLstToUpd.size()>0) {
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
            system.debug('accLstToUpd---->'+accLstToUpd);
            List<Account> AccountsToUpdate = new List<Account>();
             AccountsToUpdate.addAll(accLstToUpd);
             if(AccountsToUpdate.size()>0){
                system.debug('AccountsToUpdate---->'+AccountsToUpdate);
                update AccountsToUpdate;
             }
            //update accLstToUpd;
            TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT = false;
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
            //system.debug('++++++++++'+accLstToUpd);
        }
    } catch(Exception e) {} 
   		
   		/*******************************************************************
		 * @Description.: updating the Account's lastTouchbySalesAgent     *
		 * @updatedBy...: India team                                       *
		 * @updateDate..: 19/03/2014                                       *
		 * @Case Number.: 02432238                                         *
		 *******************************************************************/
		/*********************************************Code for Case Number:02432238 Start from here *****************************************/
    	try{
	    	User userObj = [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
	    	Profile objpro = [SELECT Name ,Id FROM Profile WHERE Id =:userObj.ProfileId];
	    	List<Account> lstParentAccount = new List<Account> (); 
	    	if(objpro.Name.toLowerCase().contains('sales') && !objpro.Name.toLowerCase().contains('engineer') ){
	    		for(Contact objContact: trigger.New){
	    			lstParentAccount.add(new Account(Id = objContact.AccountId));
	    		}
	    		AccountTriggerHelperExt.updateLastTouchedSalesPerson(lstParentAccount,userObj);
	    	}
    	}catch(Exception Ex){
			system.debug('#### Error on line - '+ex.getLineNumber());
			system.debug('#### Error message - '+ex.getMessage());
		}
		
		if(Trigger.isUpdate && trigger.isAfter){ 
	  		if(DG_DFR_Class.ContactAfterUpdate_FirstRun || test.isRunningTest()){
	  			DG_DFR_Class.DFR_ContactStatusChange(trigger.New,trigger.Old);
				DG_DFR_Class.ContactAfterUpdate_FirstRun=false;
			}
  		}
  		
  		//### Transaction Stack (
		if(DG_Transaction_Stack_Class.TSContactUpdate_FirstRun || test.isRunningTest()){
			if(trigger.isUpdate && trigger.isAfter){
				DG_Transaction_Stack_Class.Log_TS_OnContactUpdate(trigger.new,trigger.old);
			}
			DG_Transaction_Stack_Class.TSContactUpdate_FirstRun = false;
		} 
		//### Transaction Stack )
		
}