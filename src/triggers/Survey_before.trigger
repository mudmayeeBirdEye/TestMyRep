trigger Survey_before  on Survey__c (before update, before insert) {
	
		if(trigger.isInsert) {
			try {
				set<Id> contactIdSet = new set<Id>();
				for(Survey__c objSurvey:trigger.new) {
					if(objSurvey.Contact__c != null) {
						contactIdSet.add(objSurvey.Contact__c); 
					}
				}
				
				map<Id,contact> contactMap; 
				if(contactIdSet != null && contactIdSet.size()>0) {
					contactMap = new map<Id,contact>([select Ignore_Survey__c from Contact where Id IN :contactIdSet]);
				}
				
				
				for(Survey__c objSurvey:trigger.new) {
					if(objSurvey.Contact__c != null && contactMap != null && contactMap.containskey(objSurvey.Contact__c)) {
						boolean ignoreSurveyFlag = contactMap.get(objSurvey.Contact__c).Ignore_Survey__c;
						if(ignoreSurveyFlag == true) {
							objSurvey.Ignore_Contact_Survey__c = 'Yes';
						} else if(ignoreSurveyFlag == false) {
							objSurvey.Ignore_Contact_Survey__c = 'No';
						}
					}
				}	
			} catch(Exception ex) { }
		}
	
	
		/* create a new case if Resolution score is less than 3 */
	    if(trigger.isUpdate) {
	        try {
	            Integer counter = 0;
	                  for(Survey__c objSurvey:trigger.new) {
		                // added on August 3, 2011.
		                if(objSurvey.ownerId != trigger.old[counter].ownerId ) {
		                    objSurvey.Reassigned_Survey__c = 'True';
		                }
		                counter++;     
		                // end condition        
		                // This condition is modified on June 17, 2011. It is done for calling this trigger on Support Csat case only. if a survey does not have any case, will not allow to create a case here
		                 if((objSurvey.Status__c==null || objSurvey.Status__c=='') &&(Site.getName()!=null || Test.isRunningTest())){ 
		                   if((objSurvey.Q3_Score__c < 3 || (objSurvey.X2_Survey__c != null && Integer.valueof(objSurvey.X2_Survey__c) < Integer.valueof(3.00))) && objSurvey.SurveyType__c.toUpperCase().contains('SUPPORT CSAT') 
				                    && objSurvey.Case__c != null  ) {
				                    Case objCase=new Case();
				                    RecordType rt = [SELECT id FROM RecordType Where  Name='Support - DSAT' ];
				                    if(rt!=null) {
				                        objCase.RecordTypeId=rt.id;
				                    }
				                    for(Group gp:[Select id from group where Type=:'Queue' and Name='Support DSAT']) {
				                        objCase.ownerid=gp.id; 
				                    }
				                    objCase.ParentId=objSurvey.Case__c;
				                   /*Here we want to populate additional Field - The subject from the parent case (Format- DSAT For Case- +CaseNumber+CaseSubject) 
				                     Description (Format -
				                         a.Survey Comment - <Comment from survey> 
				                         b.Original case description - <Description from Parent>)
				                    */
				                    //try{
				                    Case c = [SELECT CaseNumber,Subject,Description FROM Case WHERE id=: objSurvey.Case__c];
				                             objCase.Subject = 'DSAT For Case - ' + c.CaseNumber +' - '+c.Subject ;
				                             
				                             String strSurveyComments= (objSurvey.Comments__c == null ? '' : objSurvey.Comments__c);
				                             String strCaseDescription = (c.Description == null ? '' : c.Description);
				                             
				                             objCase.Description ='Survey Comment - '+strSurveyComments+''  
				                                                 + '\n Original case description - '+ strCaseDescription;
				                    upsert objCase;
				                    // } Catch (Exception Ex){}
				                }
		            }
	           }  
	        } catch(Exception e) { }
	    }
}