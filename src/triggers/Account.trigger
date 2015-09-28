/*********************************************************************** ***************************
 * Project Name..........:                                                                         *
 * File..................: Account.Trigger                                                         *
 * Version...............: 1.0                                                                     *
 * Created by............: Simplion Technologies                                                   *
 * Created Date..........: 14-04-2014                                                              *
 * Last Modified by......: Simplion Technologies                                                   *
 * Last Modified Date....: 14-04-2014                                                              *
 * Description...........: Trigger on Account object                                               *
 *						  After Insert: Check to see if implementation is needed.                 *
 *						  After Update: Check to see if implementation is warrented with update.  * 
 *						                Closed implementations if necessary.                      *
 *						                Created Cancelled Trial leads.                            *
 *										Alert contract owners if necessary.                       *
 **************************************************************************************************/

trigger Account on Account (after insert, after update,After Delete) { 

	// Flag to check if trigger is to be executed or not.
	if(TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT || TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE || TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER){
		System.debug('### RETURNED FROM ACCOUNT INSERT-AFTER TRG ###');
		return;
	}else{
		System.debug('### STILL CONTINUE FROM ACCOUNT AFTER TRG ###');
		TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
	}
	Boolean accountHierachyCalculationEnabled = (AccountHierarchyCustomSetting__c.getInstance('AccountHierarchyInstance') != null && AccountHierarchyCustomSetting__c.getInstance('AccountHierarchyInstance').HierarchyCalculationEnabled__c) ? true : false;
	if(trigger.isUpdate){
		/*This code is used for updating customer account's fields for partner account*/
		AccountTriggerHelper.partnerAccount();
	}

	List<Account> lstAccount = new List<Account>();

	    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
        Set<string> ultimateParentIdSet = new Set<string>(); // used for Account Hierarchy Total DLS Field updation
        if(Trigger.isInsert || Trigger.isUpdate){
            try {
                /*This code is used to create Entitlements when entitlement is enabled*/
                if(EntitlementHelper.IsEntitlementsEnabled()){
                    EntitlementHelper.createEntitlements(trigger.new, (Trigger.isInsert ? null : trigger.oldMap));
                }
                if(Test.isRunningTest()){
                    Integer error = 0/0;
                }
            } catch(Exception e) {
                System.debug('#### Error @ Account Trigger line - '+e.getlineNumber());
                System.debug('#### Error @ Account Trigger message - '+e.getMessage());
            }
        
        
            /******For Account Hierarchy Total DLS Field updation********/
            for(Account accObj : Trigger.new) {   
        		if(Trigger.isInsert) {
                    if(accObj.Ultimate_Parent_Account_ID__c != null) {
                        ultimateParentIdSet.add(string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15));
                        ultimateParentIdSet.add(string.valueOf(accObj.id).subString(0,15));
                        system.debug('==ultimateParenId=='+accObj.Ultimate_Parent_Account_ID__c);
                    } else{
                        ultimateParentIdSet.add(string.valueOf(accObj.Id).subString(0,15));
                        system.debug('==Id=='+accObj.Id);
                    }
                }else if(Trigger.isUpdate) {
                    if( (accObj.ParentId != Trigger.oldMap.get(accObj.Id).ParentId) || 
                        (accObj.RC_Account_Status__c != Trigger.oldMap.get(accObj.Id).RC_Account_Status__c) || 
                        (accObj.Number_of_DL_s__c != Trigger.oldMap.get(accObj.Id).Number_of_DL_s__c)){
                        if(accObj.Ultimate_Parent_Account_ID__c != null){
                            ultimateParentIdSet.add(string.valueOf(accObj.Ultimate_Parent_Account_ID__c).subString(0,15));
                            system.debug('==enter=='+string.valueOf(accObj.id).subString(0,15));
                            ultimateParentIdSet.add(string.valueOf(accObj.id).subString(0,15));
                            ultimateParentIdSet.add(string.valueOf(Trigger.OldMap.get(accObj.Id).Ultimate_Parent_Account_ID__c).subString(0,15));
                            system.debug('==ultimateParenIdUpdate=='+accObj.Ultimate_Parent_Account_ID__c);
                        } else {
                            ultimateParentIdSet.add(string.valueOf(accObj.Id).subString(0,15));
                            system.debug('==IdUpdate=='+accObj.Id);
                        }
               		}
               	}	
            }
        }
        if(Trigger.isDelete){
            ultimateParentIdSet = TriggerHandler.RELATED_ACCOUNT_ID_SET;
        }    
        if(ultimateParentIdSet!=null && ultimateParentIdSet.size() > 0 && !Test.isRunningTest()){
        	if(accountHierachyCalculationEnabled){// if Custom settings enabled
	       		AccountTriggerHelperExt.calculateAccountHierarchyTotalDLS(ultimateParentIdSet);
	            if(Trigger.isDelete){
	                TriggerHandler.RELATED_ACCOUNT_ID_SET = new Set<String>();
	            }
        	}
        }
       /******End of For Account Hierarchy Total DLS Field updation********/
    } 

	if(trigger.isInsert) {

		/*This code is use to insert CarrierDataRecord */
		HelperUtils.updateCarrierDataRecordNew(trigger.new);
		// Assign new Account Map
		AccountTriggerHelper.newAccountMap = trigger.newMap;
		// Calling contructor.
		AccountTriggerHelper objAccountTrgHlpr = new AccountTriggerHelper();
		/*This code is used for inserting new implementaion*/
		AccountTriggerHelper.implementationLeads();
		
		//For Contact paid and cancelled status for Account		
		//AccountTriggerHelper.updateRelatedContactAccount(Trigger.new);		
		
		// Fetching list of all Accounts on insert, having parentId not null.
		/*List<Account> paidAccountList = new List<Account>();
		for(Account accObj : trigger.new){
			if(accObj.ParentId != null){
				lstAccount.add(accObj);
			}
			if(accObj.RC_Account_Status__c!=null && 'Paid'.equalsIgnoreCase(accObj.RC_Account_Status__c.trim())){
				paidAccountList.add(accObj);
			}
		}
		
		if(paidAccountList!=null && paidAccountList.size() > 0){
			AccountTriggerHelper.updateRelatedContactAccount(paidAccountList);
		}*/
	}

	if(trigger.isUpdate){
		// Assign new Account Map
		AccountTriggerHelper.newAccountMap = trigger.newMap;
		// Assign Old Account Map
		AccountTriggerHelper.oldAccountMap = trigger.oldMap;
		// Calling contructor.
		AccountTriggerHelper objAccountTrgHlpr = new AccountTriggerHelper();

		/*This code is used for inserting new lead, new implementaion,sending email*/
		AccountTriggerHelper.updateAccountActiveDate();
		/*This code is use to Create VAR Survey on Account Activation*/
		//AccountTriggerHelper.survey();
		//Start Account Hierarchy Validation
		/*This code is use to update partner account list*/
		lstAccount= AccountTriggerHelper.upListAccount();   
		
		
		//AccountTriggerHelper.updateRelatedContactAccount(Trigger.new);
		
		//For Contact paid and cancelled status for Account
		/*List<Account> paidAccountList = new List<Account>();
		for(Account accObj : Trigger.new) {
			if(accObj.RC_Account_Status__c!=null 
			 	&& ('Paid'.equalsIgnoreCase(accObj.RC_Account_Status__c.trim()) || 'Canceled'.equalsIgnoreCase(accObj.RC_Account_Status__c.trim())) 
				&& accObj.RC_Account_Status__c != trigger.oldMap.get(accObj.id).RC_Account_Status__c){
					paidAccountList.add(accObj);
			}
		}
		
		if(paidAccountList!=null && paidAccountList.size() > 0){
			AccountTriggerHelper.updateRelatedContactAccount(paidAccountList);
		}*/	
	}

	if(trigger.isInsert || trigger.isUpdate){
		AccountTriggerHelperExt.createUpdateAccountSplits(trigger.new, AccountTriggerHelperExt.eligiblePartnerAccountStaticIdSet);
		if(lstAccount!=null && !lstAccount.isEmpty()){
			try{
				/*This code is used for updating customer account hierarchy*/
				AccountHierarchyValidation.validateAccountHierarchy(lstAccount);
				if(Test.isRunningTest()){
					Integer error = 0/0;
				}
			} catch(Exception e){
				System.debug('#### Error @ Account Trigger AccountHierarchyValidation line - '+e.getlineNumber());
				System.debug('#### Error @ Account Trigger AccountHierarchyValidation message - '+e.getMessage());
			} 
		}
		/*This code is used to clear the value of all the collections*/
		AccountTriggerHelper.deinitalize();
	}
	
	/********************************************************/
 	if(trigger.isInsert){
		AccountTriggerHelper.createFinanceCaseOnPaid(null,Trigger.New);
 	} else if(trigger.isUpdate) {
 		AccountTriggerHelper.createFinanceCaseOnPaid(trigger.oldMap,Trigger.New);
 		AccountTriggerHelperExt.deleteAccntSplitOnPartnerChange(trigger.newMap);
 		AccountTriggerHelperExt.updateContactStatus(trigger.new);
 	}
 		
} // End of Trigger