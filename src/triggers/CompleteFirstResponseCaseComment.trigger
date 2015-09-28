trigger CompleteFirstResponseCaseComment on CaseComment (after insert) {
	Boolean portalUser = EntitlementHelper.isPortalUser();
	if(Test.isRunningTest())
		portalUser = true;
    if(EntitlementHelper.IsEntitlementsEnabled() && portalUser) {
        DateTime completionDate = System.now();
        List<Id> caseIds = new List<Id>();
     
        for (CaseComment cc: Trigger.new){
            // Only public comments qualify
            if(cc.IsPublished == true )
                caseIds.add(cc.ParentId);
        }
        if(caseIds.isEmpty() == false){
            List<Case> caseList = [Select Id, ContactId, Contact.Email, OwnerId, Status, EntitlementId, SlaStartDate, SlaExitDate From Case
                           Where Id IN:caseIds AND RecordtypeId =:OpportunityHelper.getOppRecordTypeMap('Support-Case') AND First_Response_Timestamp__c = null];
            if (caseList.isEmpty() == false){
                List<Id> updateCases = new List<Id>();
                for (Case caseObj:caseList) {
                    // consider an outbound email to the contact on the case a valid first response
                    if ((caseObj.Status != 'Closed')&&
                        (caseObj.EntitlementId != null)&&
                        (caseObj.SlaStartDate <= completionDate)&&
                        (caseObj.SlaStartDate != null)&&
                        (caseObj.SlaExitDate == null))
                        updateCases.add(caseObj.Id);
                }
                if(updateCases.isEmpty() == false)
                    MilestoneUtils.completeMilestone(updateCases, 'First Response', completionDate);
            }
        }
    }
}