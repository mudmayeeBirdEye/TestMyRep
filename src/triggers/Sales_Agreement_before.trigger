trigger Sales_Agreement_before on Quote (before insert,before update) {
	Map<Id, Id> oppToAccountMap = new Map<Id, Id>();
	Set<Id> oppIds = new Set<Id>();
	for(Quote quoteObj: Trigger.new) {
		oppIds.add(quoteObj.OpportunityID);
	}
	for(Opportunity oppObj : [SELECT  AccountID from Opportunity WHERE ID IN :oppIds]) {
		oppToAccountMap.put(oppObj.Id, oppObj.AccountID);
	}
	for(Quote quoteObj: Trigger.new) {
		quoteObj.Account__c = oppToAccountMap.get(quoteObj.OpportunityID);
	}
}