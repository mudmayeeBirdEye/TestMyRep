trigger NewEdge_After on NewEdgeLead__c (after insert) {
 if(trigger.isInsert){
    

    for(NewEdgeLead__c NEL: trigger.new){
	    try {
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        // by using setTargetObjectId and ownerId you can avoid daily mail message limit
	      
	        
	        String[] toAddresses = new String[] {'ringcentral@newedgenetworks.com'};       
	        //String[] toAddresses = new String[] {'alok@simplion.com'}; //Need to replace when go LIVE
	        mail.setToAddresses(toAddresses);
	        try{
	            User u = [Select u.Email From User u where  u.Username=:UserInfo.getUserName()];                        
	            String[] ccAddresses = new String[] {u.email};
	             mail.setCcAddresses(ccAddresses);
	        }catch(System.QueryException e){
	            String[] ccAddresses = new String[] {UserInfo.getUserName()};
	             mail.setCcAddresses(ccAddresses);
	        }
	       
	        mail.setSenderDisplayName('NewEdge Submission Form');
	        mail.setSubject('NewEdge lead from Ring Central');
	        
	        mail.setPlainTextBody('Please find below the details of "NewEdge lead from Ring Central" \n\n' +
	        'Information '+ '\n' +     
	        'Company Name: ' + NEL.Company_Name__c + '\n' +       
	        'Name: ' + NEL.Name__c + '\n' +       
	        'E-Mail: ' + NEL.E_mail__c + '\n' +       
	        'Phone: ' + NEL.Phone_No__c + '\n' +    
	        'RC Rep(First Name): ' + NEL.RC_Rep__c+ '\n' +      
	        'RC Rep(Last Name): ' + NEL.RC_Rep_Last_Name__c + '\n' +       
	        'Type of Lead: ' + NEL.Type_of_lead__c + '\n\n' +        
	        'Service Address '+ '\n' +     
	        'Address 1:' + NEL.Address_1__c + '\n' +       
	        'Address 2: ' + NEL.Address_2__c + '\n' +       
	        'City: ' + NEL.City__c + '\n' +       
	        'State: ' + NEL.State__c + '\n' +       
	        'Land Line Phone #: ' + NEL.Contact_No__c + '\n' +       
	        'Zip Code: ' + NEL.Zip__c + '\n\n' +   
	        'Additional Information '+ '\n' +     
	        '# Users: ' + NEL.Users__c + '\n' +   
	        'Customer Type: ' + NEL.Customer_Type__c + '\n' +   
	        'Number of Locations: ' + NEL.Number_of_locations__c + '\n' +   
	        'Current price paid (USD): ' + NEL.Current_price_paid__c + '\n' +   
	        'Contract expiration of (existing provider): ' + NEL.Contract_expiration_of_existing_provider__c + '\n\n' +   
	        'Comments from RC personnel:\n ' + NEL.Comments_from_RC_personnel__c + '\n'   );        
	        
        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
        } catch(Exception ex) {}
    }

    
 }
}