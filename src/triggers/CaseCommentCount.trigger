trigger CaseCommentCount on CaseComment (after delete, after insert, after update) {
	try {
		if(TriggerHandler.BY_PASS_CASECOMMENT_ON_INSERT || TriggerHandler.BY_PASS_CASECOMMENT_ON_UPDATE){
            System.debug('### RETURNED FROM CASECOMMENT AFTER TRG ###');
            return;
        } else {
            System.debug('### STILL CONTINUE FROM CASECOMMENT AFTER TRG ###');
        }
		/*********************To ByPass Case Trigger Code*************/
		TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
		TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
		/************************************************************/
		
		if(Trigger.isDelete) {
	    	CaseCommentCountHelper caseCommentHelpeObj = new CaseCommentCountHelper();
	        map<Id,Case> caseCommentMap = new map<Id,Case>();
		    caseCommentMap = caseCommentHelpeObj.getCaseCommentCountInfo(Trigger.old);
		    map<Id,User> createdUserMap = new  map<Id,User>();
		    createdUserMap = caseCommentHelpeObj.getcreatedUserMap(Trigger.old);
		    List<Case> CaseListToUpd = new List<Case>();
		    CaseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnDelete(Trigger.old,caseCommentMap,createdUserMap);
		    if(CaseListToUpd != null && CaseListToUpd.size()>0) {
		    	update CaseListToUpd;
		    }	
	    } else if (Trigger.isInsert || Trigger.IsUpdate) {
	    	/********************** TELUS CASE COMMENT CODE STARTS**********************************************/
	    	try{
		        if(Trigger.isInsert){
		        	TelusExternalSharingHelperCls.onLocalCaseCommentInsert(Trigger.new);
		        }
		        if(Trigger.isUpdate){
		        	TelusExternalSharingHelperCls.onLocalCaseCommentUpdate(Trigger.new);
		        }
		        
		        
		    }catch(Exception e){
		        System.debug('Exception occured IN TELUS Code for Comments.');
		    } 
		    /********************** TELUS CASE COMMENT CODE ENDS**********************************************/ 
		    CaseCommentCountHelper caseCommentHelpeObj = new CaseCommentCountHelper();
	        map<Id,Case> caseCommentMap = new map<Id,Case>();
		    caseCommentMap = caseCommentHelpeObj.getCaseCommentCountInfo(Trigger.new);
		    map<Id,User> createdUserMap = new  map<Id,User>();
		    createdUserMap = caseCommentHelpeObj.getcreatedUserMap(Trigger.new);
		    List<Case> CaseListToUpd = new List<Case>();
		    if(Trigger.isInsert) {
		    	CaseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnInsOrUpd(null,Trigger.New,caseCommentMap,createdUserMap);
		    } else if(Trigger.IsUpdate) {
		    	CaseListToUpd = caseCommentHelpeObj.getUpdatedCaseListOnInsOrUpd(Trigger.oldMap,Trigger.New,caseCommentMap,createdUserMap);
		    }
		    if(CaseListToUpd != null && CaseListToUpd.size()>0) {
		    	TriggerHandler.BY_PASS_CASE_Trigger = true; 
		    	update CaseListToUpd;
		    }
	    }	
	} catch(Exception ex){}
}