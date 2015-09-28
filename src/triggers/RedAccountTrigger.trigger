/******************************************************************************
* Project Name..........: 													  *
* File..................: RedAccountTrigger      							  *
* Version...............: 1.0 												  *
* Created by............: Simplion Technologies 							  *
* Created Date..........: 30th August 2013 									  *
* Last Modified by......: Simplion Technologies 							  *
* Last Modified Date....: 													  *
* Description...........: This trigger provides a level 1 alert for sales     * 
*						  representatives when someone goes wrong or is about *
*						  to go wrong with 1 of their owned accounts.         *
******************************************************************************/

trigger RedAccountTrigger on Account_Metric__c (before insert, before update, before delete) {
	if(Trigger.isInsert || Trigger.isUpdate){
		/* Declaring Variables*/
		// Map for <Account Id,Account Metrics Id>
		Map<Id,Id> mapAccountMetricId = new Map<Id,Id>();
		// Map for <Account Metrics Id,Account Detail>
		Map<Id,Account> mapAccountDetail =  new Map<Id,Account>();
		//Map of trigger elements
		Map<Id,Account_Metric__c> triggerMap =  new Map<Id,Account_Metric__c>(); 
		
		for(Account_Metric__c thisAccountMetric : Trigger.New){
			triggerMap.put(thisAccountMetric.Id,thisAccountMetric);
		}
		// Looping the triggered account metrics to create Map for <Account Id,Account Metrics Id>
		for(Id thisAccountMetric : triggerMap.keySet()){
			mapAccountMetricId.put(triggerMap.get(thisAccountMetric).Account_ID__c,thisAccountMetric);
		}
		
		// Looping the triggered account metrics to create Map for <Account Metrics Id,Account Detail>
		for(Account thisAccount : [SELECT Current_Owner__c,Current_Owner__r.IsActive,Id,Current_Owner__r.Email 
								   FROM Account 
								   WHERE Id in: mapAccountMetricId.keySet()]){
								   	
			mapAccountDetail.put(mapAccountMetricId.get(thisAccount.Id),thisAccount);
		}
							 
		// Looping the list of Account Metrics fetched
		for(Id thisAccountMetric : mapAccountDetail.keySet()){
			   	
			   	// Updating Current Owner field on Account Metric
			   	if(mapAccountDetail.get(thisAccountMetric).Current_Owner__r.IsActive ==  true && 
			   	   mapAccountDetail.get(thisAccountMetric).Current_Owner__c != null){
			   	   	
			   		triggerMap.get(thisAccountMetric).Account_Current_Owner__c = mapAccountDetail.get(thisAccountMetric).Current_Owner__r.Email;
			   	}
			   	else{
			   		// Fetching Default Email form custom setting.
					if(Case_Severity_1_Email__c.getInstance('Default') != NULL)
			   		 triggerMap.get(thisAccountMetric).Account_Current_Owner__c = Case_Severity_1_Email__c.getInstance('Default').Default_Email__c;		   		
			   	}
			   	system.debug('#### Account Current Owner - '+triggerMap.get(thisAccountMetric).Account_Current_Owner__c);
		}
		
		//updating account current owner
		for(Account_Metric__c thisAccountMetric : Trigger.New){
			thisAccountMetric.Account_Current_Owner__c = triggerMap.get(thisAccountMetric.Id).Account_Current_Owner__c;
		}
		
		/* For Graduation Score Card.
		 * Calculate completion Rate and Date of Adoption Phase and Graduation Phase over the Account Metric Object. 
		 */
		 GraduationScoreCardHelper.adopGradCompRateOnAccountMetric(Trigger.New, Trigger.oldMap); 
	}
	
	if(Trigger.isDelete){
		
		/* For Graduation Score Card.
		 * Calculate completion Rate and Date of Adoption Phase and Graduation Phase over the deletion of Account Metric Object. 
		 */
		GraduationScoreCardHelper.calculateCompletionOnAccountMetricDeletion(Trigger.old);
	}
}