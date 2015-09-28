/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_QuoteTriggerHelper {/*

    static testMethod void myUnitTest() { 
    	
    	SET<id> zqObjList = new SET<id>(); 
    	
    	zqu__Quote__c q = new zqu__Quote__c();
        q.Name ='Test Name';
        q.tax_jurisdiction__c = '262144';
        //q.zqu__Opportunity__c = createOpportunity().Id;
        q.Account_Zip_Code__c = '1001';
        insert q;
       
    	zqObjList.add(q.id);
    	
    	zqu__QuoteCharge__c zuoraQuoteCharge = new zqu__QuoteCharge__c();
        zuoraQuoteCharge.Name ='Test Name';
        zuoraQuoteCharge.zqu__Quote__c = q.Id;
        zuoraQuoteCharge.zqu__Total__c = 500;
        //zuoraQuoteCharge.zqu__ProductRatePlanCharge__c = createzProductRatePlanCharge().id;
        insert zuoraQuoteCharge;
        
    	SET<id> zquObjList = new SET<id>(); 
        zquObjList.add(zuoraQuoteCharge.id);
        
        QuoteTriggerHelper.isAfterInsertNew(zquObjList,zqObjList);
    }*/
}