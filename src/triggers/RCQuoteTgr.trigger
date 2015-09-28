trigger RCQuoteTgr on RC_Quote__c (before insert, before update, after update, before delete) {
		
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		
		/************************************** Setting Up Is Primary Flag,End Date and Opportunity Field Calculation****************************************/
		Set<Id> opptyIdSet = new Set<Id>();		
		Set<Id> opptyPrimaryIdSet = new Set<Id>();
			
		for(RC_Quote__c rcQuote : trigger.New){
			if(trigger.isInsert){
				if(rcQuote.Opportunity__c != NULL){
					opptyIdSet.add(rcQuote.Opportunity__c);
					rcQuote.IsPrimary__c = true;	
				}
				if(rcQuote.Start_Date__c != null && rcQuote.Initial_Term__c != null && Trigger.isInsert){
	                rcQuote.End_Date__c = rcQuote.Start_Date__c.addMonths(integer.valueOf(rcQuote.Initial_Term__c)) ;
	            } 
			}else{
				
				if(rcQuote.Opportunity__c != NULL && (rcQuote.Total_12M_Amount__c == 0 ||
					(rcQuote.Total_Initial_Amount__c!=trigger.oldMap.get(rcQuote.Id).Total_Initial_Amount__c) ||
					(rcQuote.Total_12M_Amount__c!=trigger.oldMap.get(rcQuote.Id).Total_12M_Amount__c) || 
					(rcQuote.Total_MRR__c!=trigger.oldMap.get(rcQuote.Id).Total_MRR__c) ||
					(rcQuote.IsPrimary__c!=trigger.oldMap.get(rcQuote.Id).IsPrimary__c && rcQuote.IsPrimary__c==true))
				   ){
				   	if(rcQuote.IsPrimary__c!=trigger.oldMap.get(rcQuote.Id).IsPrimary__c && rcQuote.IsPrimary__c==true){
						opptyPrimaryIdSet.add(rcQuote.Opportunity__c);
				   	}
				   	opptyIdSet.add(rcQuote.Opportunity__c);				   	
				}
				if(System.today() > rcQuote.End_Date__c && rcQuote.Start_Date__c != null && rcQuote.Renewal_Term__c != null){
	                rcQuote.End_Date__c = rcQuote.Start_Date__c.addMonths(integer.valueOf(rcQuote.Renewal_Term__c)) ;   
	            }else if(rcQuote.End_Date__c == null){
	                if(rcQuote.Start_Date__c != null && rcQuote.Initial_Term__c != null){
	                    if(rcQuote.Start_Date__c.addMonths(integer.valueOf(rcQuote.Initial_Term__c)) > System.today()){
	                        rcQuote.End_Date__c = rcQuote.Start_Date__c.addMonths(integer.valueOf(rcQuote.Initial_Term__c)) ;
	                    }else{
	                        if(rcQuote.Start_Date__c != null && rcQuote.Renewal_Term__c != null){
	                            rcQuote.End_Date__c = rcQuote.Start_Date__c.addMonths(integer.valueOf(rcQuote.Renewal_Term__c)) ;
	                        }
	                    }
	                }
	            }
			}
		}
		if((opptyIdSet!=null && opptyIdSet.size() > 0) || (opptyPrimaryIdSet!=null && opptyPrimaryIdSet.size() >0)){				
			map<id,Opportunity> opportunityMap = new map<id,Opportunity>([Select id,Primary_Opportunity_Contact__c,Total_Initial_Amount__c,Amount,Total_MRR__c,
																			X12_Month_Booking__c, Probability
																			from Opportunity where id in:opptyIdSet]);
			List<RC_Quote__c> rcQuoteList = new List<RC_Quote__c>();
			if(trigger.isInsert){
				rcQuoteList = [SELECT Id,Opportunity__c,IsPrimary__c FROM RC_Quote__c WHERE IsPrimary__c=true AND Opportunity__c IN:opptyIdSet];
			}else{
				rcQuoteList = [SELECT Id,Opportunity__c,IsPrimary__c FROM RC_Quote__c WHERE IsPrimary__c=true AND Opportunity__c IN:opptyPrimaryIdSet];
			}
			for(RC_Quote__c rcQuoteObj : rcQuoteList){
				rcQuoteObj.IsPrimary__c = false;
			}
			if(!rcQuoteList.isEmpty()){			
				update rcQuoteList;			
			}
			
			Boolean opportunityModified = false;
			List<OpportunityContactRole> opportunityContactRoleList = new List<OpportunityContactRole>();
			List<Opportunity> oppObjToUpdateList = new List<Opportunity>();
			for(RC_Quote__c rcQuote : trigger.New){
				if(opportunityMap!=null && opportunityMap.get(rcQuote.Opportunity__c)!=null && rcQuote.IsPrimary__c==true){
					opportunityModified = true;
					Opportunity oppObjToUpdate = new Opportunity();
					oppObjToUpdate = opportunityMap.get(rcQuote.Opportunity__c);
					/*oppObjToUpdate.Total_Initial_Amount__c = (rcQuote.Total_Initial_Amount__c!=null && rcQuote.Total_Initial_Amount__c!=0?rcQuote.Total_Initial_Amount__c:oppObjToUpdate.Total_Initial_Amount__c);
					oppObjToUpdate.X12_Month_Booking__c = (rcQuote.Total_12M_Amount__c!=null && rcQuote.Total_12M_Amount__c!=0 ?rcQuote.Total_12M_Amount__c:oppObjToUpdate.X12_Month_Booking__c);
					oppObjToUpdate.Total_MRR__c = (rcQuote.Total_MRR__c!=null && rcQuote.Total_MRR__c!=0?rcQuote.Total_MRR__c:oppObjToUpdate.Total_MRR__c);
					oppObjToUpdate.Amount = (rcQuote.Total_12M_Amount__c!=null && rcQuote.Total_12M_Amount__c!=0 ?rcQuote.Total_12M_Amount__c:oppObjToUpdate.X12_Month_Booking__c);*/
					
					oppObjToUpdate.Total_Initial_Amount__c = rcQuote.Total_Initial_Amount__c;
					oppObjToUpdate.X12_Month_Booking__c = rcQuote.Total_12M_Amount__c;
					oppObjToUpdate.Total_MRR__c = rcQuote.Total_MRR__c;
					oppObjToUpdate.Amount = rcQuote.Total_12M_Amount__c;
					oppObjToUpdate.Primary_Opportunity_Contact__c = (rcQuote.Contact__c!=null?rcQuote.Contact__c:NULL);
					//opportunityMap.get(rcQuote.Opportunity__c).Total_Calculated_Amount__c = (rcQuote.Total_Calculated_Amount__c!=null?rcQuote.Total_Calculated_Amount__c:0);
					//opportunityContactRoleList.add(new OpportunityContactRole(opportunityId=opportunityMap.get(rcQuote.Opportunity__c).id,ContactId=rcQuote.Contact__c,IsPrimary=true,role='Business User'));
					oppObjToUpdateList.add(oppObjToUpdate);
				}	
			}
			if(oppObjToUpdateList!=null && oppObjToUpdateList.size() > 0 && opportunityModified){
				TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE() ; 
				TriggerHandler.BY_PASS_CONTACT_ON_UPDATE() ;
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE() ; 
				update oppObjToUpdateList;
				TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
				TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
				TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = false;
			}
		}		
		/******************************************************************************/		
	}
	
	if(trigger.isBefore && trigger.isDelete){
		Set<id> oppIdSet = new Set<Id>();
		for(RC_Quote__c quoteObj : trigger.old) {
			if(quoteObj.IsPrimary__c){
				oppIdSet.add(quoteObj.Opportunity__c);
			}
		}
		if(oppIdSet!=null && oppIdSet.size() > 0){
			map<id,Opportunity> opportunityMap = new map<id,Opportunity>([Select id,Primary_Opportunity_Contact__c,Total_Initial_Amount__c,Total_MRR__c,X12_Month_Booking__c,
																			Amount,Probability 
																			from Opportunity where id in:oppIdSet]);
			Boolean opportunityModified = false;
			for(RC_Quote__c quoteObj : trigger.old){
				if(quoteObj.IsPrimary__c && opportunityMap!=null && opportunityMap.get(quoteObj.Opportunity__c)!=null){
					opportunityMap.get(quoteObj.Opportunity__c).Total_Initial_Amount__c = 0;
					opportunityMap.get(quoteObj.Opportunity__c).X12_Month_Booking__c = 0;
					opportunityMap.get(quoteObj.Opportunity__c).Total_MRR__c = 0;
					if(opportunityMap.get(quoteObj.Opportunity__c).Probability != NULL ){
						opportunityMap.get(quoteObj.Opportunity__c).Amount = ((opportunityMap.get(quoteObj.Opportunity__c).X12_Month_Booking__c * opportunityMap.get(quoteObj.Opportunity__c).Probability)/100).setScale(2);	
					}
					//opportunityMap.get(quoteObj.Opportunity__c).Total_Calculated_Amount__c = 0;
					opportunityModified = true;
				}
			}
			if(opportunityMap!=null && opportunityMap.size() > 0 && opportunityModified){    
				update opportunityMap.values();
			}
		}
	}
    
    if(trigger.isAfter &&  trigger.isUpdate){
    	try{
    	/****************  Insert & Update Sales Agreement Record on Status Changes of Quote Start**************************/
			List<Quote> listQuoteTOIns = new List<Quote>();
			List<Quote> listQuoteTOUpd = new List<Quote>();
			set<Id> accountId = new set<Id>();
			// Map Of Quote Details
			Map<Id,RC_Quote__c> quotesMap = new Map<Id,RC_Quote__c>();
			List<RC_Quote__c> quoteObjList = [select Opportunity__c,End_Date__c, Opportunity__r.AccountId,Quote_Type__c, Agreement_Status__c,Total_MRR__c, 
													Start_Date__c, Total_Initial_Amount__c,Total_12M_Amount__c,Name, Renewal_Term__c, Initial_Term__c,
													(Select Id, Status From Quotes__r where status = 'Active' limit 1) 
													from RC_Quote__c
													where Id IN : Trigger.newmap.keyset()];
			for(RC_Quote__c quoteObj : quoteObjList) {
				if(!String.isBlank(quoteObj.Opportunity__r.AccountId)) {
					accountId.add(quoteObj.Opportunity__r.AccountId);
					quotesMap.put(quoteObj.Id,quoteObj);	
				}								
			}
			// Map Of Account with Active Sales Agreement 
			map<Id,List<Quote>> quoteAccountMap = new map<Id,List<Quote>>();
			if(accountId != null && accountId.size()>0) {
				List<Account> accountList = [Select Id,(Select Status From Quotes__r where status = 'Active' limit 1) 
												From Account where ID IN :accountId];
				for(Account accountObj : accountList) {
					quoteAccountMap.put(accountObj.id, accountObj.Quotes__r);
				}
			}
			for(RC_Quote__c quoteObj : trigger.new) {
				system.debug('@@@@@@@@@@ ############ Trigger '+ quoteObj.Total_MRR__c );
				if(quotesMap != null && quotesMap.get(quoteObj.id).Quote_Type__c == 'Agreement' && 
						quotesMap.get(quoteObj.id).Agreement_Status__c == 'Active'
						&& Trigger.oldMap.get(quoteObj.id).Agreement_Status__c != 'Active') {
					if(quoteAccountMap != null && quotesMap.get(quoteObj.id).Opportunity__r.AccountId != null &&
						quoteAccountMap.get(quotesMap.get(quoteObj.id).Opportunity__r.AccountId).size()== 0) {
						Quote quoteObjTOIns = new Quote();
						quoteObjTOIns.Name = quotesMap.get(quoteObj.id).Name;
						quoteObjTOIns.OpportunityId = quotesMap.get(quoteObj.id).Opportunity__c;
						quoteObjTOIns.Initial_Term_months__c = quotesMap.get(quoteObj.id).Initial_Term__c == null? '0' : String.valueOf(quotesMap.get(quoteObj.id).Initial_Term__c);
				 		quoteObjTOIns.Term_months__c = quotesMap.get(quoteObj.id).Renewal_Term__c == null ? '0' : String.valueOf(quotesMap.get(quoteObj.id).Renewal_Term__c);
						System.debug('>>>Date>>'+quotesMap.get(quoteObj.id).Start_Date__c);
						quoteObjTOIns.Start_Date__c = (quotesMap.get(quoteObj.id).Start_Date__c != null)? quotesMap.get(quoteObj.id).Start_Date__c : System.today();
						System.debug('>>>Date11>>'+quotesMap.get(quoteObj.id).Start_Date__c);
						quoteObjTOIns.End_Date__c  = quotesMap.get(quoteObj.id).End_Date__c;
						quoteObjTOIns.Total_12M_Amount__c = quotesMap.get(quoteObj.id).Total_12M_Amount__c;
						quoteObjTOIns.Total_Initial_Amount__c = quotesMap.get(quoteObj.id).Total_Initial_Amount__c;
						quoteObjTOIns.Total_MRR__c = quotesMap.get(quoteObj.id).Total_MRR__c;
						quoteObjTOIns.status = quotesMap.get(quoteObj.id).Agreement_Status__c;
						quoteObjTOIns.Related_RC_Quote__c = quoteObj.id;
						quoteObjTOIns.account__c = quotesMap.get(quoteObj.id).Opportunity__r.AccountId;
						//-------------------------------------------As/Simplion/8/20/2014---------------------------------
						quoteObjTOIns.PDF_Template_Version__c = quoteObj.PDF_Template_Version__c;						
						listQuoteTOIns.add(quoteObjTOIns);
						System.Debug('listQuoteTOIns' + listQuoteTOIns);
					} else {
						quoteObj.addError('An active sales agreement already exists for this account.Please inactive before activating a new one.');
					} 
				} else if(quotesMap != null && quoteObj.Quote_Type__c == 'Agreement' && 
							Trigger.oldMap.get(quoteObj.id).Agreement_Status__c == 'Active' &&
							(quoteObj.Agreement_Status__c != 'Active' )) {
					if(quotesMap.get(quoteObj.id).Quotes__r != null && quotesMap.get(quoteObj.id).Quotes__r.size() == 1) {
						Quote quoteObjTOUpd = new Quote(Id = quotesMap.get(quoteObj.id).Quotes__r[0].id);
						quoteObjTOUpd.status = quoteObj.Agreement_Status__c;
						//-------------------------------------------As/Simplion/8/20/2014---------------------------------
						quoteObjTOUpd.PDF_Template_Version__c = quoteObj.PDF_Template_Version__c;						
						listQuoteTOUpd.add(quoteObjTOUpd);	
					}		
				}
			}
			if(listQuoteTOIns != null && listQuoteTOIns.size()>0) {
				System.Debug('listQuoteTOIns>>' + listQuoteTOIns);
				insert listQuoteTOIns;
			}
			if(listQuoteTOUpd != null && listQuoteTOUpd.size()>0) {
				update listQuoteTOUpd;
			}
    	}catch(Exception e){}
    }
}