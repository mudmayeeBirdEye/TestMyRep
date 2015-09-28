/******************************************************************************
* Project Name..........: 													  *
* File..................: Severity1_CaseTrigger 							  *
* Version...............: 1.0 												  *
* Created by............: Simplion Technologies 							  *
* Created Date..........: 30th August 2013 									  *
* Last Modified by......: Simplion Technologies 							  *
* Last Modified Date....: 													  *
* Description...........: This trigger is to inform you that the              *
*						  Account has a severity 1 case.                      *
******************************************************************************/

trigger Severity1_CaseTrigger on Case (after insert, after update) {
	
	// returns true/false on successfull completion of the class method
	Boolean completionFlag;
	
	system.debug('#### Trigger start ');
		
		//Calling helper method to execute business logic
		Severity1_CaseHelperClass classCall =  new Severity1_CaseHelperClass();
		completionFlag = classCall.checkForEmail(trigger.newMap);
		if(completionFlag ==  false){
			system.debug('#### email not sent exception raised');
		}
	
	system.debug('#### Trigger stop ');
}