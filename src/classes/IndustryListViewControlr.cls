/*-----------------------------------------------------------------------------
* Case Name.............: Sales Battle Cards                                  *
* File..................: SalesBattleCards.Page                               *
* Created by............: Simplion Technologies                               *
* Created Date..........: 25-06-2014                                          *
* Last Modified by......: Simplion Technologies                               *
* Description...........: This Controller is used  for SalesBattleCards Page  *
------------------------------------------------------------------------------>*/
public class IndustryListViewControlr {
	Public List<Industry__c> indsList {get;set;} 
	public List<Industry__c> industryList {get;set;} 
	public string strIndustryName {get;set;}
	public String indName{get;set;} 
    
    /*.....Constructor........*/
	public IndustryListViewControlr(ApexPages.StandardController controller) {
        try {
            industryList = new list<industry__c>();
            indsList = new list<industry__c>();
            String ctrlId = controller.getId();
            if(String.isNotBlank(ctrlId)) {
                list<industry__c> indusLst = [SELECT id, name FROM industry__c WHERE id =:ctrlId];
                if(indusLst != null && indusLst.size() > 0){
                    strIndustryName = indusLst[0].name;
                    if(string.isNotBlank(strIndustryName)) {
                        industryList = getIndustry(strIndustryName);
                    } 
                }
            }
            //DISPLAY SE VERTICAL NAME IN FRON OF INDUSTRY SUBJECT 
            Map<String,Industry_Name__c> allIndust = Industry_Name__c.getAll();
            Map<String,Industry_Name__c> allIndustIgnoreCase = new Map<String,Industry_Name__c>();
            
            for(String str : allIndust.keyset()){
                Industry_Name__c ind = allIndust.get(str);
                allIndustIgnoreCase.put(str.trim().toLowerCase(), ind);
            }            
            Industry_Name__c ind = allIndustIgnoreCase.get(strIndustryName.trim().toLowerCase());
            indName = ind.SE_Name__c;
        } catch(Exception ex) {}
    }     
       
    /*.....Method to get the list of Industry object record.......*/
    public List<Industry__c> getIndustry(String myIndustryName) {
		indsList = new list<industry__c>();
		indsList = [select id, Name ,How_the_Phone_System_works__c ,Value_Benefit__c,Industry_Pain_Point__c,Pain_Reliever__c,
						Web_Resource__c,LastModifiedDate ,What_it_is__c from Industry__c   
						where name = :myIndustryName ORDER BY  LastModifiedDate DESC];			
		return indsList;
    }
		
	/*....Method to return on Salesforce List View Page ....  */
    public PageReference redirectToPartnerRequest() {
        PageReference objPageRef = new PageReference('/apex/ListIndustry');   
        objPageRef.setRedirect(true); 
        return objPageRef;
    }      
 }