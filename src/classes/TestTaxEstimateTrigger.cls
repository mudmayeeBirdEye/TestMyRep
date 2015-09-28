/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 */
@isTest
private class TestTaxEstimateTrigger {/*

    static testMethod void myUnitTest() {
        test.startTest();
        Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c='Sales Agents & Resellers';
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
        
        // inserting zuora product
        zqu__ZProduct__c zProduct = new zqu__ZProduct__c();
        zProduct.Name ='Test Name';
        zProduct.zqu__ZuoraId__c = '1237182341341245srf';
        zProduct.zqu__SKU__c= '424sdf';
        insert zProduct;
        
        
        
        // inserting zuora Product Rate Plan
        zqu__ProductRatePlan__c zProductRatePlan = new zqu__ProductRatePlan__c();
        zProductRatePlan.Name ='Test Name';
        zProductRatePlan.zqu__ZProduct__c = zProduct.id;
        zProductRatePlan.zqu__ZuoraId__c = '1237182341341245srf';
        insert zProductRatePlan;
        
        // inserting zuora Product Rate Plan Charge
        zqu__ProductRatePlanCharge__c zProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        zProductRatePlanCharge.Name ='Test Name';
        zProductRatePlanCharge.CrmTaxCode__c = '1';
        zProductRatePlanCharge.zqu__ProductRatePlan__c = zProductRatePlan.id;
        zProductRatePlanCharge.zqu__ZuoraId__c = '1237182341341245srf';
        zProductRatePlanCharge.ChargeType__c = 'test';
        insert zProductRatePlanCharge;
        
        // inserting Zuora Quote 
        
        List<zqu__Quote__c> qLst = new List<zqu__Quote__c>();
        zqu__Quote__c q = new zqu__Quote__c();
        q.Name ='Test Name';
        q.tax_jurisdiction__c = '262144';
        q.zqu__Opportunity__c = Oppval.Id;
                
        // inserting Zuora Quote 
        zqu__Quote__c qq = new zqu__Quote__c();
        qq.Name ='Test Name';
        qq.tax_jurisdiction__c = '262144';
        qq.zqu__Opportunity__c = Oppval.Id;
        qq.QuoteType__c = 'Sales Agreement';
        qq.SalesAgreementStatus__c = 'Active';
        qLst.add(q);
        qLst.add(qq);
        insert qLst;
        qq.SalesAgreementStatus__c = 'InActive';
        update qq;
        
        // inserting Zuora Quote Charge 
        zqu__QuoteCharge__c zuoraQuoteCharge = new zqu__QuoteCharge__c();
        zuoraQuoteCharge.Name ='Test Name';
        zuoraQuoteCharge.zqu__Quote__c = q.Id;
        zuoraQuoteCharge.zqu__Total__c = 500;
        zuoraQuoteCharge.zqu__ProductRatePlanCharge__c = zProductRatePlanCharge.id;
        insert zuoraQuoteCharge;
        
        
        //inserting sf_tax 
        sf_tax__c sftax= new sf_tax__c();
        sftax.JURISDICTION__c= '262144';
        sftax.TAXCATEGORY__c= '1';
        sftax.TAXABLEMEASUREPERCENT__c = 100;
        sftax.VALUE__c = 6 ;
        sftax.TAXLEVEL__c = 1;
        sftax.COLLECTIONTYPENAME__c = 'Fee';
        insert sftax;
        
        test.stopTest(); 
        
    }*/
}