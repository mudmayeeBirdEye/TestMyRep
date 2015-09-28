/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class TestAddressValidationController {/*
	
		
	static Opportunity createOpportunity() { 
		Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c='';
        acctest.Partner_ID__c ='123';
        acctest.BillingPostalCode = '1001';
        //acctest.RecordTypeId  = '01280000000UERq';
        insert acctest;
        
		Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = '3. Qualified';
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.JURISDICTION__c = '262144';
        //Oppval.RecordTypeId = '01280000000UEtu';
        insert Oppval;
        return Oppval;
	}
	static Opportunity createOpportunity2() {
		Account acctest1 = new Account();
        acctest1.Name='TestAccount';
        acctest1.RC_Attribution_Channel__c='';
        acctest1.Partner_ID__c ='123';
        acctest1.BillingPostalCode = '';
        //acctest.RecordTypeId  = '01280000000UERq';
        insert acctest1;
        
		Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest1.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = '3. Qualified';
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.JURISDICTION__c = '';
        //Oppval.RecordTypeId = '01280000000UEtu';
        insert Oppval;
        return Oppval;
	}
	static zqu__ZProduct__c createzProduct() {
		// inserting zuora product
        zqu__ZProduct__c zProduct = new zqu__ZProduct__c();
        zProduct.Name ='Test Name';
        zProduct.zqu__ZuoraId__c = '1237182341341245srf';
        zProduct.zqu__SKU__c= '424sdf';
        insert zProduct;
        return zProduct;
	}
	static zqu__ProductRatePlan__c createzProductRatePlan() {
		// inserting zuora Product Rate Plan
        zqu__ProductRatePlan__c zProductRatePlan = new zqu__ProductRatePlan__c();
        zProductRatePlan.Name ='Test Name';
        zProductRatePlan.zqu__ZProduct__c = createzProduct().id;
        zProductRatePlan.zqu__ZuoraId__c = '1237182341341245srf';
        insert zProductRatePlan;
        return zProductRatePlan;
	}
	static zqu__ProductRatePlanCharge__c createzProductRatePlanCharge() {
		// inserting zuora Product Rate Plan Charge
        zqu__ProductRatePlanCharge__c zProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        zProductRatePlanCharge.Name ='Test Name';
        zProductRatePlanCharge.CrmTaxCode__c = '1';
        zProductRatePlanCharge.zqu__ProductRatePlan__c = createzProductRatePlan().id;
        zProductRatePlanCharge.zqu__ZuoraId__c = '1237182341341245srf';
        zProductRatePlanCharge.ChargeType__c = 'test';
        insert zProductRatePlanCharge;
        return zProductRatePlanCharge;
	}
	static zqu__Quote__c createQuote() {
		// inserting Zuora Quote 
        zqu__Quote__c q = new zqu__Quote__c();
        q.Name ='Test Name';
        q.tax_jurisdiction__c = '262144';
        q.zqu__Opportunity__c = createOpportunity().Id;
        q.Account_Zip_Code__c = '1001';
        insert q;
        return q;
	}
	static zqu__QuoteCharge__c createzuoraQuoteCharge() {
		// inserting Zuora Quote Charge 
        zqu__QuoteCharge__c zuoraQuoteCharge = new zqu__QuoteCharge__c();
        zuoraQuoteCharge.Name ='Test Name';
        zuoraQuoteCharge.zqu__Quote__c = createQuote().Id;
        zuoraQuoteCharge.zqu__Total__c = 500;
        zuoraQuoteCharge.zqu__ProductRatePlanCharge__c = createzProductRatePlanCharge().id;
        insert zuoraQuoteCharge;
        return zuoraQuoteCharge;
	}
	static sf_tax__c createsftax() {
		//inserting sf_tax 
        sf_tax__c sftax= new sf_tax__c();
        sftax.JURISDICTION__c= '262144';
        sftax.TAXCATEGORY__c= '1';
        sftax.TAXABLEMEASUREPERCENT__c = 100;
        sftax.VALUE__c = 6 ;
        sftax.TAXLEVEL__c = 1;
        sftax.COLLECTIONTYPENAME__c = 'Fee';
        insert sftax;
        return sftax;
	}
	
	static void createzAdd() {
		Zuora_Address__c zAdd = new Zuora_Address__c();
        zAdd.City_Locality__c = 'abc' ;
        zAdd.Jcode__c = '262144';
        zAdd.Locality__c = '0' ;
        zAdd.P_Code__c = '1';
        zAdd.Zip_Code__c = '1001' ;
        insert zAdd;
        createsftax();
	}
    static testMethod void myUnitTest() {
    	//TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
    	//TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
    	/*TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
    	TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
    	TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
        createzAdd();
        Opportunity opp = createOpportunity();
        
        test.startTest();
                
        PageReference pageRef = Page.AddressValidationPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',opp.Id );
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        AddressValidationController ObjAddressValidationController = new AddressValidationController(sc);
        AddressValidationController ObjAddressValidationController2 = new AddressValidationController();
       	ObjAddressValidationController.strOppId = opp.Id;
	   	ObjAddressValidationController.strAddressId = 'strAddressId';
	    ObjAddressValidationController.strAddress = 'strAddress';
	    ObjAddressValidationController.isJURISDICTIONFound = true;
	    ObjAddressValidationController.isAddressEmpty = false;
	    ObjAddressValidationController.strSelectedID = '262144';
	    ObjAddressValidationController.objOPP = new opportunity(id = opp.Id);
	    ObjAddressValidationController.JCode = '';
	    ObjAddressValidationController.titleBarMessage = '';
	    ObjAddressValidationController.ZipFound = true;
	    ObjAddressValidationController.currentCallSource = '';
	    
        ObjAddressValidationController.ValidateAccountAddress();
        ObjAddressValidationController.CreateQuote();
        ObjAddressValidationController.updateJURISDICTIONId(opp,'262144');
        ObjAddressValidationController.skip();
        ObjAddressValidationController.getAddressDetail(opp);
        ObjAddressValidationController.getAddress('qe','wer','qwer','qwer','qrwe');
        
        test.stopTest();
        
    }
    static testMethod void myUnitTest2() {
        createzAdd();
        Opportunity opp = createOpportunity2();
        
        test.startTest();
                
        PageReference pageRef = Page.AddressValidationPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',opp.Id );
                
        ApexPages.StandardController sc1 = new ApexPages.StandardController(opp);
        AddressValidationController ObjAddressValidationController1 = new AddressValidationController(sc1);
        AddressValidationController ObjAddressValidationController22 = new AddressValidationController();
       	ObjAddressValidationController1.strOppId = opp.Id;
	   	ObjAddressValidationController1.strAddressId = 'strAddressId';
	    ObjAddressValidationController1.strAddress = 'strAddress';
	    ObjAddressValidationController1.isJURISDICTIONFound = true;
	    ObjAddressValidationController1.isAddressEmpty = false;
	    ObjAddressValidationController1.strSelectedID = '262144';
	    ObjAddressValidationController1.objOPP = new opportunity(id = opp.Id);
	    ObjAddressValidationController1.JCode = '';
	    ObjAddressValidationController1.currentCallSource = 'ViewTax';
	    ObjAddressValidationController1.titleBarMessage = '';
	    ObjAddressValidationController1.ZipFound = true;
	    ObjAddressValidationController1.ValidateAccountAddress();
        ObjAddressValidationController1.CreateQuote();
        ObjAddressValidationController1.updateJURISDICTIONId(opp,'');
        ObjAddressValidationController1.skip();
        ObjAddressValidationController1.getAddressDetail(opp);
        ObjAddressValidationController1.matchAddress('test');
        ObjAddressValidationController1.getAddress('qe','wer','qwer','qwer','qrwe');
        test.stopTest();
        
    }*/
}