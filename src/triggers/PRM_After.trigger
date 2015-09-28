trigger PRM_After on Partner_Request__c (after insert, after update) {
  /*
    When you find an existing partner with the same name in your trigger and status=Declilned / Rejected, 
    we need to update the status back to New.
  */
    PRMHelper PRMHelperObj = new PRMHelper(trigger.new); 
    if(trigger.isInsert){
	 	system.debug('@@@@@@@@@@@@@@@@+ On insertinggggggggg');
	 	PRMHelperObj.onCheckDuplicateAccount(trigger.new);   
    	PRMHelperObj.onInsertPRM(trigger.new);
	}       
	if(trigger.isUpdate){
		system.debug('@@@@@@@@@@@@@@@@+ Updatingggggggg') ;   
     	PRMHelperObj.onUpdatePRM(trigger.new);
     }
}