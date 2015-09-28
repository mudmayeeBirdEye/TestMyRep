trigger PRM_Before on Partner_Request__c (before insert, before update) {

        
   if(trigger.isInsert){
        //List<Account> PRMAcct = new Account[]{};
        Profile proff = [select Name from Profile where Id = :UserInfo.getProfileId()];
        for(Partner_Request__c PRM : Trigger.new){  
        	if(PRM.Partner_Phone__c!=null && PRM.Partner_Country__c!=null){
        		PRM.Original_Partner_Phone__c = PRM.Partner_Phone__c;
        		PRM.Partner_Phone__c = ValidationUtility.validatePhoneNumber(PRM.Partner_Phone__c,PRM.Partner_Country__c);
        	}
        	
        	/* Added by simplion TEchnology on to change on partner type based on recordtype on partner request Object */
			if(!proff.Name.containsIgnoreCase('Channel')){    
				if(string.isNotBlank(PRM.Reseller_Partner_Type__c) && PRM.Reseller_Partner_Type__c == 'Regular Partner'){
				  PRM.Partner_Type__c ='Master Agent';				  
				}else if (string.isNotBlank(PRM.Reseller_Partner_Type__c) && PRM.Reseller_Partner_Type__c == 'ISV Partner'){
				 	PRM.Partner_Type__c ='ISV Partner';
				}      
			}
        	
        	//Integer iCount = 0;	  
        	//PRM.DSR_USER__c = UserInfo.getUserId(); 
			/*try
			{        	       
	        	iCount = [SELECT  count() FROM Account where (Account.Name=:PRM.Partner_Company_Name__c and Account.Name != '') and Account.Type = 'Partner'];
	        	
			}catch(Exception e){			
				
			}	        
			
	        if(iCount > 0){
	        		        	
	        	 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		         String[] toAddresses = new String[] {'rcsfsync@ringcentral.com'}; //Need to replace when go LIVE --> rcsync
		         mail.setToAddresses(toAddresses);
		         String[] ccAddresses = new String[] {'bonniel@ringcentral.com','danielle.hopkins@ringcentral.com','rachel.mackie@ringcentral.com',
		         										'anne.malaluan@ringcentral.com'}; //bonniel@ringcentral.com 
				 mail.setCcAddresses(ccAddresses);
	        	 mail.setSenderDisplayName('Partner Request Form');
	        	 mail.setSubject('Partner Request - Duplicate Record');
	       		 mail.setPlainTextBody('Account with following company name is already with us \n\n' +
	       		 'Account with Company Name: ' + PRM.Partner_Company_Name__c + '  ' + '\n\n' );	 
	       		 try{      		 
	        	 	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	       		 }catch(Exception exp){} 
	        }
	               
	        /*
	        List<Account> acc = [SELECT  Name FROM Account where Account.Name=:PRM.Partner_Company_Name__c and Account.Type = 'Partner' limit 1000];
	        
	        if(acc.size() == 0){        
		      
	         }
	         else
	         {
		         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		         String[] toAddresses = new String[] {'rcsfsync@ringcentral.com'}; //Need to replace when go LIVE --> rcsync
		         mail.setToAddresses(toAddresses);
		         String[] ccAddresses = new String[] {'bonniel@ringcentral.com'}; //bonniel@ringcentral.com
				 mail.setCcAddresses(ccAddresses);
	        	 mail.setSenderDisplayName('Partner Request Form');
	        	 mail.setSubject('Partner Request - Duplicate Record');
	       		 mail.setPlainTextBody('Account with following company name is already with us \n\n' +
	       		 'Account with Company Name: ' + PRM.Partner_Company_Name__c + '  ' + '\n\n' );	       		 
	        	 Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
	        }
        	*/
        
       }
       //upsert PRMAcct;
       
  }
  
  if(trigger.isUpdate){
 		for(Partner_Request__c PRM :Trigger.New){
 			if(PRM.Partner_Phone__c!=null && PRM.Partner_Country__c!=null){
 				if(PRM.Partner_Phone__c!=trigger.oldMap.get(PRM.Id).Partner_Phone__c || PRM.Partner_Country__c!=trigger.oldMap.get(PRM.Id).Partner_Country__c){ 										
        			PRM.Partner_Phone__c = ValidationUtility.validatePhoneNumber(PRM.Partner_Phone__c,PRM.Partner_Country__c);
 				}
 			}
 		}
  }
}