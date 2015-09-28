/************************************ Generate PDF for Quote ***** Created By : Simplion Technologies************************************/
public with sharing class GeneratePdfController {/*
    public String SURL = ApexPages.currentPage().getParameters().get('SURL');
    public string sfSessionId = ApexPages.currentPage().getParameters().get('SID');
    public String quoteId = ApexPages.currentPage().getParameters().get('QID');
    public String brand = ApexPages.currentPage().getParameters().get('brand');
    public String quoteType = ApexPages.currentPage().getParameters().get('Qtype');
    public String selectTemplateId { get; set; }
    public String strSessionId{get;set;}  
    public Zuora.zApi.LoginResult obj{get;set;}
    public List<zqu__Quote_Template__c> templates { get; set; }
    public map<id,zqu__Quote_Template__c> templateMap = new map<id,zqu__Quote_Template__c>();
    public boolean showPanel {get;set;}
    public GeneratePdfController() {
    	try{
    		showPanel = true;
    		if(String.isBlank(brand)){
    			brand = 'US';
    		}
    		if(String.isBlank(quoteType)){
    			quoteType = 'Quote';
    		}
    		if(!String.isBlank(brand)){
		        templates = [SELECT Id, Quote_Type__c,Is_Active__c,zqu__Template_Id__c ,zqu__Description__c,Ranking__c ,Name FROM zqu__Quote_Template__c WHERE Brand__c INCLUDES (:brand)
		                            AND Quote_Type__c=:quoteType AND Is_Active__c = true ORDER BY Ranking__c ASC];
		        for(zqu__Quote_Template__c temp : templates ){
		            templateMap.put(temp.Id,temp);
		        }
		        if(!templates.isEmpty()){
		        	selectTemplateId = templates[0].id;
		        }else{
		        	selectTemplateId = '';
		        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'No active template found for this type of Quote/Sales Agreement.'));
		        }
		        if(!test.isRunningTest()){
		        	Zuora.zApi objZApi=new Zuora.zApi();
		        	objZApi.setEndpoint('https://www.zuora.com/apps/services/a/48.0');
			        //obj=objZApi.zlogin('rczuora-prod@ringcentral.com', 'fP9NL*quv4*');
			        obj=objZApi.zlogin();
			        strSessionId=obj.Session;	
		        }else{
		        	this.strSessionId = 'kjasdfo123943-2';
		        	System.debug('@@@@@@@ strSessionId ='+this.strSessionId);
		        }
		         
        	}else{
        		showPanel = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Invalid Brand name OR No template found for this Quote/Sales Agreement'));
        	}  	
    	}catch(Exception e ){}
    }
    public pageReference confirm(){
    	try{
    		System.debug('@@@@@@@ selectTemplateId = '+selectTemplateId);
    		System.debug('@@@@@@@ '+ApexPages.currentPage().getUrl());
    		System.debug('######## '+ ApexPages.currentPage().getParameters().get('SURL'));
	        String templateID = '';
	        if(templateMap.containsKey(selectTemplateId)){
	        	templateID = templateMap.get(selectTemplateId).zqu__Template_Id__c ;	
	        }
	        System.debug('@@@@@@@ quoteID ='+quoteID);
	        System.debug('@@@@@@@ sfSessionId ='+sfSessionId);
	        System.debug('@@@@@@@ templateID ='+templateID);
	        System.debug('@@@@@@@ strSessionId ='+this.strSessionId);
	        string redrectURL = 'https://www.zuora.com/apps/servlet/GenerateQuote?attachToOpportunity=true&format=pdf&locale=en_US&quoteId='+quoteID+'&serverUrl='+SURL+'&sessionId='+sfSessionId+'&templateId='+templateID+'&useSFDCLocale=1&ZSession='+strSessionId;
	        pageReference pgRef = new pageReference(redrectURL); 
	        return pgRef;
    	}catch(Exception e ){return null;}    
    }*/
}