trigger Knowledge_Article on RCNEW_Knowledge_Article__c (before insert,before update) {
/*
if(Trigger.isBefore){
   for(RCNEW_Knowledge_Article__c objKnowledgeArticle:trigger.new){
       try{
        objKnowledgeArticle.Composite_key__c= objKnowledgeArticle.Section__c+'_'+objKnowledgeArticle.Brand__c+
                                                                '_'+objKnowledgeArticle.RCVersion__c+'_'+Integer.valueOf(objKnowledgeArticle.Article_List_Order__c);
                                                                
        objKnowledgeArticle.Composite_key2__c= objKnowledgeArticle.Section__c+'_'+objKnowledgeArticle.Brand__c+
                                                                '_'+objKnowledgeArticle.RCVersion__c+'_'+objKnowledgeArticle.ArticleNumber__c;  
     }
	   catch(Exception exp){
	   	   objKnowledgeArticle.Composite_key__c= objKnowledgeArticle.Section__c+'_'+objKnowledgeArticle.Brand__c+
	                                                                '_'+objKnowledgeArticle.RCVersion__c+'_'+objKnowledgeArticle.Article_List_Order__c;
	                                                                
	        objKnowledgeArticle.Composite_key2__c= objKnowledgeArticle.Section__c+'_'+objKnowledgeArticle.Brand__c+
	                                                                '_'+objKnowledgeArticle.RCVersion__c+'_'+objKnowledgeArticle.ArticleNumber__c;  
	        Exception_And_Notification_History__c exceptionObj = new Exception_And_Notification_History__c();
			exceptionObj.Object_Type__c = 'Exception';
			exceptionObj.content_label_01__c = 'File Associated';
			exceptionObj.content_label_02__c = 'Line Number';
			exceptionObj.content_label_03__c = 'Exception';
			exceptionObj.content_label_04__c = 'Get Stack Trace String';
			exceptionObj.content_label_05__c = 'Details';
			exceptionObj.content_var_01__c ='Knowledge_Article trigger';
			exceptionObj.File_Associated__c = 'Knowledge_Article trigger';
			ExceptionAndNotificationHelper.trackExceptions(exceptionObj, exp);
   }

}

}*/
}