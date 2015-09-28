/**********************************************************
Trigger on Task object
After Delete: Prevents non-admin user from deleting Tasks.
/**********************************************************/

trigger TaskSaver on Task (after insert, after update, after delete) {
	// Get the current user's profile name
	Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];

	if(trigger.isDelete){
		// If current user is not a System Administrator, do not allow Attachments to be deleted
		if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {
			for (Task t : Trigger.old) {
				t.addError('Unable to delete tasks.');
			}  
		}
	}

	/*********************************************************************************
	 * @Discription.......: updating Account LastTouchSalesPerson Value  when Task   *
	 *					    is insert or updated                                     *
	 * @lastModifiedDate..: 2/04/2014                                                *
	 * @LastModifiedBy....: India Team                                               * 
	 * @Case number.......: 02432238                                                 *
	 ******************************case:02432238 Start here***************************/
	if(trigger.isInsert || trigger.isUpdate){
		try{
			User userObj = [SELECT Id, FirstName, Lastname, Name, Email, Phone, ProfileId FROM User WHERE Id =: UserInfo.getUserId()];
			//Set<Id> setAccountId = new set<Id>(); 
			List<Account> lstParentAccount = new List<Account>();
			if(prof.Name.toLowerCase().contains('sales') && !prof.Name.toLowerCase().contains('engineer') ){
				for(Task Taskobj: trigger.New){
					String id = Taskobj.whatId;
					String PrefixOfId = id.subString(0,3);
					if(PrefixOfId == '001'){
						Account newOrUpdatedTaskofAccount = new Account(Id = Taskobj.whatId); 
						lstParentAccount.add(newOrUpdatedTaskofAccount);
					}  
				}
				AccountTriggerHelperExt.updateLastTouchedSalesPerson(lstParentAccount,userObj);
			}
		}catch(Exception Ex){
			system.debug('#### Error on line - '+ex.getLineNumber());
			system.debug('#### Error message - '+ex.getMessage());
		}		    
	/*******************************case:02432238 Ends here****************************/

	}
}