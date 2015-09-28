/*******************************************************************************************************
* Project Name..........: Case # 03487050 DocuSign Status in PRM                                       *
* File..................: DocuSignStatusRelatedList.class                                              *
* Version...............: 1.0                                                                          *
* Created by............: eugenebasianomutya                                                           *
* Created Date..........: 23-04-2015                                                                   *
* Last Modified by......: eugenebasianomutya                                                           *
* Last Modified Date....: 23-04-2015                                                                   *
* Description...........: Class to display the DocuSign Status in Section in Account for Partner User. *
********************************************************************************************************/

public with sharing class DocuSignStatusRelatedList {
    private Account acc; 
    
    public DocuSignStatusRelatedList(ApexPages.StandardController stdController) {
        this.acc = (Account)stdController.getRecord();
    }
    
    public list<dsfs__DocuSign_Status__c> getDocuSignStatus()
    {        
                              
        //Retrieve DocuSign of the Quote/s
        list<dsfs__DocuSign_Status__c> DocSignStatus = new list<dsfs__DocuSign_Status__c>();
        
        DocSignStatus = [SELECT id, Name, dsfs__Subject__c, dsfs__Envelope_Status__c,  
                                dsfs__Sent_Date_Time__c, dsfs__Days_to_Complete__c, dsfs__Sender__c
                         FROM dsfs__DocuSign_Status__c 
                         WHERE dsfs__Company__c =: acc.Id ]; 
        
        if (DocSignStatus == null || DocSignStatus.size()==0){
            return null;
        }else{
            return DocSignStatus;
        }
    } 
}