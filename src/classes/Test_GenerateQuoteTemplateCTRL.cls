@isTest
private class Test_GenerateQuoteTemplateCTRL {
	static testMethod void myUnitTest() {
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
	    TriggerHandler.BY_PASS_CASE_ON_INSERT = true;
	    TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
	    TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
	    TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
	    TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
	    TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
    
	    Account acctest = new Account();
	    acctest.Name = 'TestAccount';
	    acctest.RC_Attribution_Channel__c = 'Sales Agents & Resellers';
	    acctest.Partner_ID__c ='123';
	    acctest.Current_Owner__c = Userinfo.getUserId();
	    acctest.RC_User_ID__c = 'test123';
	    insert acctest;
    
    	Merge_Fields_Mapping__c mc1 = new Merge_Fields_Mapping__c(name='Account',Display_Name__c='Account',Dependency__c='Opportunity',
                                                        Dependent_Relationship_Name__c='AccountId');
    	Merge_Fields_Mapping__c mc2 = new Merge_Fields_Mapping__c(name='Contact',Display_Name__c='Contact',Dependency__c='RC_Quote__c',
                                                        Dependent_Relationship_Name__c='Contact__c');
    	Merge_Fields_Mapping__c mc3 = new Merge_Fields_Mapping__c(name='Line_Item__c',Display_Name__c='Line Items',Dependency__c='RC_Quote__c',
                                                       Order_By__c='Order__c', Required_Fields__c='Sub_Category__c,Total_Initial_Price__c,Total_12_Month_Price__c');
                                                       
   		Merge_Fields_Mapping__c mc4 = new Merge_Fields_Mapping__c(name='Opportunity',Display_Name__c='Opportunity',Dependency__c='RC_Quote__c',
                                                       Dependent_Relationship_Name__c='Opportunity__c');
   		Merge_Fields_Mapping__c mc5 = new Merge_Fields_Mapping__c(name='RC_Product_Line_Item__c',Display_Name__c='RC Product Line Item',Dependency__c='Line_Item__c',
                                                       Dependent_Relationship_Name__c='RC_Product_Line_Item__c');
                                                       
   		Merge_Fields_Mapping__c mc6 = new Merge_Fields_Mapping__c(name='RC_Product__c',Display_Name__c='RC Product',Dependency__c='RC_Product_Line_Item__c',
                                                       Dependent_Relationship_Name__c='RC_Product__c', Required_Fields__c='Sub_Category__c');
                                                                                                         
    	Merge_Fields_Mapping__c mc7 = new Merge_Fields_Mapping__c(name='RC_Quote__c',Display_Name__c='Quote');
    	List<Merge_Fields_Mapping__c> mergeCustomSettingsList = new List<Merge_Fields_Mapping__c>{mc1,mc2,mc3,mc4,mc5,mc6,mc7};
    	insert mergeCustomSettingsList;
    	Test.startTest();  
    
		Contact c = new Contact();
    	c.LastName = 'contactLast1';
    	c.AccountId = acctest.Id;   //[SELECT id FROM Account WHERE name=: acctest.Name].id;
    	c.email='test11@rc.com';
    	c.Phone='1234567890';
    	insert c;
    
    	Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Opportunity; 
    	Map<String,Schema.RecordTypeInfo> opportunityRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    
    	Opportunity Oppval = new Opportunity();
    	Oppval.Name = 'Test Opp';
    	Oppval.AccountId = acctest.Id;
    	Oppval.Type = 'Existing Business';
    	Oppval.StageName = '3. ActivePipe';
    	Oppval.Sales_Model__c = 'Direct';
    	Oppval.CloseDate = System.Today() + 10;
    	Oppval.CurrencyIsoCode = 'USD';
	    Oppval.Brand_Name__c= 'RingCentral';
	    Oppval.RecordTypeId = opportunityRecordTypeInfo.get('Sales Opportunity').getRecordTypeId();
	    Oppval.Agent_Email_Address__c='test@test.com';
	    Oppval.RC_User_ID__c = Userinfo.getUserId();
	    oppval.OwnerId = Userinfo.getUserId();
	    insert Oppval;
    
	    Quote quoteObj = new Quote();
	    quoteObj.OpportunityId = Oppval.id;
	    quoteObj.Account__c = acctest.id;
	    quoteObj.Name = 'Test Quote';
	    quoteObj.Status = 'Draft';
	    insert quoteObj;
    
	    RC_Quote__c objQuote = new RC_Quote__c();
	    objQuote.Agreement_Status__c = 'test';
	    objQuote.Approved_Status__c = 'ets';
	    objQuote.Contact__c = c.Id;
	    objQuote.Renewal_Term__c = '0';
	    objQuote.Start_Date__c = System.today();
	    insert objQuote;
	
		List<RC_Product__c> rcProductList = new List<RC_Product__c>();
    	List<RC_Product_Line_Item__c> rcProductLineItemList = new List<RC_Product_Line_Item__c>();
    
    
	    RC_Product__c objProduct1 = new RC_Product__c();
	    objProduct1.Name ='Service1';
	    objProduct1.Category__c = 'Service';
	    objProduct1.Sub_Category__c = 'Main';
	    objProduct1.Charge_Term__c = 'Annual';
	    objProduct1.Service_Type__c = 'Office';
	    objProduct1.SKU__c  = 'SKU1';
	    objProduct1.Dependent_SKUs__c = 'SKU2';         
	    rcProductList.add(objProduct1);
	    
	    RC_Product__c objProduct2 = new RC_Product__c();
	    objProduct2.Name ='AddOn1';
	    objProduct2.Category__c = 'Service';
	    objProduct1.Sub_Category__c = 'Contact Center';
	    objProduct2.Charge_Term__c = 'Monthly';
	    objProduct2.Service_Type__c = 'Office';
	    objProduct2.Product_Type__c = 'DL';
	    objProduct2.SKU__c  = 'SKU2'; 
	    rcProductList.add(objProduct2);
    	/*
		RC_Product__c objProduct3 = new RC_Product__c();
		objProduct3.Name ='AddOn1';
		objProduct3.Category__c = 'AddOn';
		objProduct3.Charge_Term__c = 'Annual';
		objProduct3.Service_Type__c = 'Office';
		objProduct3.SKU__c  = 'SKU3';
		objProduct3.Dependent_SKUs__c = 'SKU4';         
		rcProductList.add(objProduct3);
		
		RC_Product__c objProduct4 = new RC_Product__c();
		objProduct4.Name ='AddOn1';
		objProduct4.Category__c = 'AddOn';
		objProduct4.Charge_Term__c = 'Monthly';
		objProduct4.Service_Type__c = 'Office';
		objProduct4.Product_Type__c = 'DL';
		objProduct4.SKU__c  = 'SKU4';
		rcProductList.add(objProduct4);
		*/
		insert rcProductList;

		RC_Product_Line_Item__c objProductLinItm1 = new RC_Product_Line_Item__c();
		objProductLinItm1.Name = 'test1';
		objProductLinItm1.RC_Product__c= objProduct1.id;
		objProductLinItm1.Lower_Limit__c = 0;
		objProductLinItm1.Upper_Limit__c = 10;
		objProductLinItm1.Price__c = 10;
		objProductLinItm1.RC_Currency__c = 'USD';
		objProductLinItm1.isActive__c = true;
		objProductLinItm1.Allowed_Record_Type__c = 'Sales Opportunity';
		objProductLinItm1.Max_Discount__c = 1;          
		rcProductLineItemList.add(objProductLinItm1);

		RC_Product_Line_Item__c objProductLinItm2 = new RC_Product_Line_Item__c();
		objProductLinItm2.Name = 'test2';
		objProductLinItm2.RC_Product__c= objProduct2.id;
		objProductLinItm2.Lower_Limit__c = 0;
		objProductLinItm2.Upper_Limit__c = 10;
		objProductLinItm2.Price__c = 10;
		objProductLinItm2.RC_Currency__c = 'USD';
		objProductLinItm2.isActive__c = true;
		objProductLinItm2.Allowed_Record_Type__c = 'Sales Opportunity';
		objProductLinItm2.Max_Discount__c = 1;          
		rcProductLineItemList.add(objProductLinItm2);
		/*
		RC_Product_Line_Item__c objProductLinItm3 = new RC_Product_Line_Item__c();
		objProductLinItm3.Name = 'test3';
		objProductLinItm3.RC_Product__c= objProduct3.id;
		objProductLinItm3.Lower_Limit__c = 0;
		objProductLinItm3.Upper_Limit__c = 10;
		objProductLinItm3.Price__c = 10;
		objProductLinItm3.RC_Currency__c = 'USD';
		objProductLinItm3.isActive__c = true;
		objProductLinItm3.Allowed_Record_Type__c = 'Sales Opportunity';
		objProductLinItm3.Max_Discount__c = 1;          
		rcProductLineItemList.add(objProductLinItm3);

		RC_Product_Line_Item__c objProductLinItm4 = new RC_Product_Line_Item__c();
		objProductLinItm4.Name = 'test4';
		objProductLinItm4.RC_Product__c= objProduct4.id;
		objProductLinItm4.Lower_Limit__c = 0;
		objProductLinItm4.Upper_Limit__c = 10;
		objProductLinItm4.Price__c = 10;
		objProductLinItm4.RC_Currency__c = 'USD';
		objProductLinItm4.isActive__c = true;
		objProductLinItm4.Allowed_Record_Type__c = 'Sales Opportunity';
		objProductLinItm4.Max_Discount__c = 1;          
		rcProductLineItemList.add(objProductLinItm4);
		*/
        insert rcProductLineItemList;     
		List<Line_Item__c> liList = new List<Line_Item__c>();
		Line_Item__c li1 = new Line_Item__c();
        li1.RC_Quote__c = objQuote.Id;
        li1.RC_Product_Line_Item__c = objProductLinItm1.Id;
        li1.Opportunity__c = Oppval.Id;
        li1.Quantity__c = 1;
        li1.Effective_Discount__c = 10;
        li1.Total_Price__c = 10;
        li1.Total_12_Month_Price__c = 10;
        li1.Total_Initial_Price__c = 10;
            
        liList.add(li1);
            
        Line_Item__c li2 = new Line_Item__c();            
		li2.RC_Quote__c = objQuote.Id;
        li2.RC_Product_Line_Item__c = objProductLinItm2.Id;
        li2.Opportunity__c = Oppval.Id;
        li2.Quantity__c = 1;
		li2.Effective_Discount__c = 10;
		li2.Total_Price__c = 10;
		li2.Total_12_Month_Price__c = 10;
        li2.Total_Initial_Price__c = 10;
		liList.add(li2);
			
		insert liList;
		GenerateQuoteTemplateCTRL.DynamicData dd = new GenerateQuoteTemplateCTRL.DynamicData();
		                           
		RC_Quote_Template__c objRCQuoteTemplate = new RC_Quote_Template__c();
		objRCQuoteTemplate.Brand__c = 'RingCentral';
		objRCQuoteTemplate.Name = 'test';
		objRCQuoteTemplate.Description__c = 'test123';
		objRCQuoteTemplate.Type__c = 'test';
		objRCQuoteTemplate.RC_Quote__c = objQuote.Id;
		objRCQuoteTemplate.Opportunity__c = oppval.Id;
            
		insert objRCQuoteTemplate;
            
		TemplateSections__c objTS = new TemplateSections__c();
		String content1 = 'This 123 is my place where I can work MAIN_{!Line_Item__c.name} and to show the progress MAIN_{!Line_Item__c.quantity__c}. so whats are your thoughts.';
		objTS.Content_1__c = content1; 
		String content2 = 'This 123 is my place where I can work MAIN_{!RC_Product_Line_Item__c.name} and to show the progress MAIN_{!RC_Product_Line_Item__c.name}. so whats are your thoughts.';
		objTS.Content_2__c = content2;
		String content3 = 'This 123 is my place where I can work MAIN_{!RC_Product__c.name} and to show the progress MAIN_{!RC_Product__c.name}. so whats are your thoughts.';
		objTS.Content_3__c = content3;
		String content4 = 'This 123 is my place where I can work {!Contact.Name} and to show the progress {!Account.name}. so whats are your thoughts.';
		objTS.Content_4__c = content4;
		String content5 = 'This 123 is my place where I can work {!Opportunity.Name} and to show the progress {!RC_Quote__c.name}. so whats are your thoughts.';
		objTS.Content_5__c = content5;
		insert objTS;
            
        TemplateSections__c templateSecObj = new TemplateSections__c(Name='testSection',Content_1__c='testDatatestDatatestDatatestData',
        Description__c='testDescription');
        insert templateSecObj;
            
        TemplateSectionJunction__c objTSJ = new TemplateSectionJunction__c();
        objTSJ.Position__c =1.00;
        objTSJ.RC_Quote_Template__c = objRCQuoteTemplate.id;
        objTSJ.Template_Section__c = objTS.id;
        insert objTSJ;
            
        GenerateQuoteTemplateCTRL.strStaticCondition = '';
        GenerateQuoteTemplateCTRL.strStaticItem = '';
        GenerateQuoteTemplateCTRL.strStaticCondition = '';
        GenerateQuoteTemplateCTRL.strStaticTerm = '';
       	String pointValue = String.valueOf(5.0).split('\\.')[1];
		String numberString = String.valueOf(5);
            
        ApexPages.currentPage().getParameters().put('quoteid',quoteObj.Id);
        ApexPages.currentPage().getParameters().put('opptyid',Oppval.Id);
            
        String previewId ='';
        string str ='hi';
        ApexPages.StandardController controller = new ApexPages.StandardController(objRCQuoteTemplate);
        GenerateQuoteTemplateCTRL objGQT = new GenerateQuoteTemplateCTRL(controller);
        objGQT.addTemplateSection();
        //objGQT.selectedSection ='a4AS0000000CcBeMAK';
        objGQT.selectedSection = templateSecObj.Id;
       	previewId = quoteObj.Id; 
        objGQT.prepareDynamicPreview(previewId);
        objGQT.onPreview();
        objGQT.addTemplateSection();
        objGQT.saveTemplate();
        objGQT.deleteTemplateSection();
        test.stopTest();
    }
}