/*************************************************
Trigger on Event object
After Delete: Prevents non-admin user from deleting Events.
/************************************************/

trigger EventSaver on Event (after delete,after insert, after update) {
	
	if(TriggerHandler.BY_PASS_EVENT_ON_INSERT || TriggerHandler.BY_PASS_EVENT_ON_UPDATE || TriggerHandler.BY_PASS_EVENT_ON_AFTER){
        System.debug('#### RETURNED FROM EVENT INSERT / UPDATE TRG ####');
        return;
    } else {
    	TriggerHandler.BY_PASS_EVENT_ON_AFTER = true;
        System.debug('#### STILL CONTINUE FROM EVENT INSERT / UPDATE TRG ####');
    }
	// Contains set of user Id, #implementationTestLink
	Set<String> useridSet = new Set<String>();
	Map<String,Implementation__c> mapImplementation = new Map<String,Implementation__c>();
	List<Implementation__c> finalImplementationToUpdate = new List<Implementation__c>();
	
	// Get the current user's profile name
	Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
	  
	// If current user is not a System Administrator, do not allow Attachments to be deleted
	if(Trigger.isDelete) {
		if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {
			for (Event e : Trigger.old) {
				e.addError('Unable to delete events.');
			}  
		}
	}
	
	/*******************************************************************
	 * @Description.: updating the Account's lastTouchbySalesAgent     *
	 * @updatedBy...: India team                                       *
	 * @updateDate..: 19/03/2014                                       *
	 * @Case Number.: 02432238                                         *
	/*******************************************************************/
	/*********************************************Code for Case Number:02432238 Start from here *****************************************/
	if(Trigger.isInsert || Trigger.isUpdate) {
		try{
	    	User userObj = [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
	    	List<Account> accountList = new List<Account>();
	    	if(prof.Name.toLowerCase().contains('sales') && !prof.Name.toLowerCase().contains('engineer') ){
	    		for(Event eventObj: trigger.new){
	    			String eventParentId = eventObj.whatId;
	    			if(eventParentId != null) {
						String PrefixOfId = eventParentId.subString(0,3);
						if(PrefixOfId == '001'){
							accountList.add(new Account(id = eventParentId));
						}
	    			}
	    		}
	    		AccountTriggerHelperExt.updateLastTouchedSalesPerson(accountList,userObj);
	    	}
    	}catch(Exception Ex){
			system.debug('#### Error on line - '+ex.getLineNumber());
			system.debug('#### Error message - '+ex.getMessage());
		}
	}
	
	/**********************************************************************************************
    * @Description : Code is for updating the Most Recent Implementation Event Id.                *
    *                                                                                             *
    * TO BE DELETED.                                                                              *
    **********************************************************************************************/
	if(trigger.isInsert){
		try{
			for(Event thisRecord : trigger.new){
				if(!String.isBlank(thisRecord.CustomerId__c)) {
					useridSet.add(thisRecord.CustomerId__c);
				}
			} 
			if(useridSet != null && useridSet.size()>0) {
				for(Implementation__c implemetationObj : [SELECT RC_USER_ID__c, Account__c,Account__r.Id, Account__r.isAppointmentScheduled__c, 
				                                                 Account__r.Last_Reminder_Date__c, Account__r.Last_Reminder_Date_1__c,
				                                                 Account__r.Last_Reminder_Date_2__c, Account__r.Last_Reminder_Date_3__c 
				                                          FROM Implementation__c 
				                                          WHERE RC_USER_ID__c IN :useridSet]) {
				                                          	
				    system.debug('#### Implementation Account - '+implemetationObj.Account__r);
					mapImplementation.put(implemetationObj.RC_USER_ID__c,implemetationObj);
				}
			}	
			for(Event thisRecord : trigger.new){
				if(mapImplementation != null && !String.isBlank(thisRecord.CustomerId__c) && mapImplementation.get(thisRecord.CustomerId__c) != null) {	
					Implementation__c implementationObj = new Implementation__c(Id = mapImplementation.get(thisRecord.CustomerId__c).id);
					implementationObj.Most_Recent_Implementation_Event__c = thisRecord.Id;
					system.debug('#### Implementation to be updated - '+implementationObj);
					finalImplementationToUpdate.add(implementationObj);	
				}
			}
			if(finalImplementationToUpdate != null && finalImplementationToUpdate.size() > 0){
	  			update finalImplementationToUpdate;
	  		}
		}catch(Exception ex){
			system.debug('#### Exception at Line = '+ex.getLineNumber()+' Message = '+ex.getMessage());
		}
	}
}