trigger DG_Transaction_Stack_Trigger on Transaction_Stack__c (before insert) {
	if(trigger.isInsert && trigger.isBefore){
		DG_Transaction_Stack_Class.Populate_DFR_Data(trigger.New);
		DG_Transaction_Stack_Class.TransactionType_Owner(trigger.New);
		DG_Transaction_Stack_Class.TransactionType_Campaign(trigger.New);
	}
}