@isTest
private class callingrates_test {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Folder fd = [SELECT Id FROM Folder WHERE Name='VIIFPRInternationalCallingRates'];
        Blob blbObj = Blob.valueOf('44,United Kingdom,1418,United Kingdom - Freephone,Freephone,National Destinations (03 and 05),500,Free');
        Document doc = new Document(Name='BT_Calling_Rates', Body = blbObj ,folderId = fd.Id,isPublic=true,type='csv' );
        insert doc;
		
        callingrates ctrlObj = new callingrates();
        ctrlObj.strSelectedCountry = 'afghanistan';
        ctrlObj.getCountryWiseRates();
        ctrlObj.strSelectedCountry = 'a_';
        ctrlObj.getAllInternationRates();
        ctrlObj.strDomesticName = '1223';
        ctrlObj.getDomesticRates();
        ctrlObj.strDomesticName = 'a_';
        ctrlObj.getAllDomesticRates();
        ctrlObj.getShowDomesticResultPanel();
        ctrlObj.getShowInternationalResultPanel();
    }
}