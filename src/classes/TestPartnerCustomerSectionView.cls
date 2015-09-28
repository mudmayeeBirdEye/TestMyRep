@isTest
private class TestPartnerCustomerSectionView{
    static testmethod void UnitPartCustSecVw(){
        Schema.DescribeSObjectResult resultAccount = Account.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByIdAccount = resultAccount.getRecordTypeInfosByName();         
        Schema.DescribeSObjectResult resultled = Lead.SObjectType.getDescribe();
        Map<string,Schema.RecordTypeInfo> rtMapByIdled = resultled.getRecordTypeInfosByName();
                  
        Account accObj = new Account();
        accObj.Name = 'Test Partner Account';
        accObj.RecordTypeId = rtMapByIdAccount.get('Partner Account').getRecordTypeId();
        accObj.Partner_ID__c = '1600';
        accObj.Type = 'Partner';
        insert accObj;
        
        Account accObj1 = new Account();
        accObj1.Name = 'Test Customer Account';
        accObj1.RecordTypeId = rtMapByIdAccount.get('Customer Account').getRecordTypeId();
        accObj1.Partner_ID__c = '1600';
        accObj1.ParentId = accObj.id;
        accObj1.Type = 'Customer';
        insert accObj1;

         PartnerCustomerSectionView partCustSecVw = new PartnerCustomerSectionView(new ApexPages.StandardController(accObj));
      
    }

 }