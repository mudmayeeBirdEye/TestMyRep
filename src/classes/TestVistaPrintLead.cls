/**
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestVistaPrintLead {

    static testMethod void VistaPrintLeadTest() {
    	
		   test.startTest();
		   Messaging.InboundEmail email = new Messaging.InboundEmail();
		   Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		   Messaging.InboundEmail.Textattachment inAtt = new Messaging.InboundEmail.Textattachment();
		   Messaging.InboundEmail.Binaryattachment inBtt = new Messaging.InboundEmail.Binaryattachment();

		   email.subject = 'test';
		   env.fromAddress = 'user@acme.com';
		
		   // set the body of the attachment
		   inAtt.body = 'VPlast,VPfirst,999,123 happy drive,apt 234,san jose,IL,95128,US,4085556666,6508885555,StandardTollFreeNumberOffer,jesse@jimmyjack.com*EOL*';
		   inAtt.fileName = 'attach.csv';
		   inAtt.mimeTypeSubType = 'plain/txt';
		
		   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt }; 

		   // call the class and test it with the data in the testMethod
		   VistaPrintLead emailServiceObj = new VistaPrintLead();
		   //Counter__c c=[select value__c from Counter__c where name='Partner'];
		   emailServiceObj.handleInboundEmail(email, env );
		   //Counter__c c2=[select value__c from Counter__c where name='Partner'];
		  // system.assert(c2.value__c > c.value__c);
		   
		   inAtt.body = 'VPlast1,VPfirst1,999,123 happy drive,san jose,,IL,95128,UK,4085556666,6508885555,StandardTollFreeNumberOffer,jesse1@jimmyjack.com*EOL*';
		   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt };
		  // emailServiceObj.handleInboundEmail(email, env );	   
   
		   inAtt.body = 'VPlast2,VPfirst2,999,123 happy drive,,floor5,san jose,IL,95128,US,4085556666,6508885555,WebsiteDashboardOffer,jesse2@jimmyjack.com*EOL*';
		   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt };
		   emailServiceObj.handleInboundEmail(email, env );
		   
		   inAtt.body = 'VPlast3,VPfirst3,999,123 happy drive,floor5,,san jose,IL,95128,US,4085556666,6508885555,jesse2@jimmyjack.com*EOL*';
		   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt };
		   //emailServiceObj.handleInboundEmail(email, env );
		   
	   	   inAtt.body = 'VPlast3,VPfirst3,999,123 happy drive,floor5,san jose,,IL,95128,US,4085556666,6508885555,jesse2@jimmyjack.com*EOL*';
		   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt };
		   //emailServiceObj.handleInboundEmail(email, env );
		
		   
		//   inAtt.body = ',Valued Customer,999,123 happy drive,,floor5,san jose,,IL,95128,US,4085556666,6508885555,jesse4@jimmyjack.com*EOL*';
		//   email.textAttachments = new Messaging.inboundEmail.Textattachment[] {inAtt };
		//   emailServiceObj.handleInboundEmail(email, env );	
		   
		   ///////////////////////////// binary tests
		   
		   inBtt.body = blob.valueOf('VPlast,VPfirst,999,123 happy drive,apt 234,san jose,IL,95128,US,4085556666,6508885555,StandardTollFreeNumberOffer,jesse@jimmyjack.com*EOL*');
		   inBtt.fileName = 'attach.csv';
		   //inBtt.mimeTypeSubType = 'plain/txt';

		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt }; 
		
		   // call the class and test it with the data in the testMethod
		   // VistaPrintLead emailServiceObj = new VistaPrintLead();
		   emailServiceObj.handleInboundEmail(email, env );
	
		   
		   inBtt.body = blob.valueOf('VPlast1,VPfirst1,999,123 happy drive,san jose,,IL,95128,US,4085556661,6508885551,jesse1@jimmyjack.com*EOL*');
		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
		   //emailServiceObj.handleInboundEmail(email, env );	   
		   
		   	   inBtt.body = blob.valueOf(',Valued Customer,999,123 happy drive,,floor5,san jose,IL,95128,US,4085556662,6508885552,jesse2@jimmyjack.com*EOL*');
		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
		   //emailServiceObj.handleInboundEmail(email, env );	
		   
		   	   	   inBtt.body = blob.valueOf(',Valued Customer,999,123 happy drive,floor5,,san jose,IL,95128,US,4085556663,6508885553,jesse3@jimmyjack.com*EOL*');
		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
		   //emailServiceObj.handleInboundEmail(email, env );
		   
		//   	   	   inBtt.body = blob.valueOf(',Valued Customer,999,123 happy drive,floor5,san jose,,IL,95128,US,4085556666,6508885555,jesse2@jimmyjack.com*EOL*');
		//   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
		//   emailServiceObj.handleInboundEmail(email, env );
		   
		   
		   	   	   inBtt.body = blob.valueOf(',Valued Customer,999,123 happy drive,floor5,san jose,,IL,95128,US,4085556664,6508885554,jesse4@jimmyjack.co.uk*EOL*');
		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
		  // emailServiceObj.handleInboundEmail(email, env );
		   
		   	   	   inBtt.body = blob.valueOf(',Valued Customer,999,123 happy drive,floor5,san jose,,IL,95128,US,444085556666,446508885555,jesse5@jimmyjack.com*EOL*');
		   email.binaryAttachments = new Messaging.inboundEmail.Binaryattachment[] {inBtt };
   		//emailServiceObj.handleInboundEmail(email, env );
   		test.stopTest();
	}	
}