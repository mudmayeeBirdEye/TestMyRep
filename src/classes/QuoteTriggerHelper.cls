/*
  *This class is being used by TaxEstimateTrigger on zqu__QuoteCharge__c object.
  *Updating/inserting the zqu__QuoteCharge__c object based on jurisdiction ID value and change in selected products .
*/

public class QuoteTriggerHelper{/*
    
    public set<Id> qChargeIdSet = new set<Id>();
    public set<Id> quoteIdSet = new set<Id>();
    public map<Id,zqu__Quote__c> quoteMap = new map<id,zqu__Quote__c>();
    public List<zqu__Quote__c> quoteList = new List<zqu__Quote__c>();
    public map<string,zuoraUtility.QuoteWrapper2> taxesMap = new map<string,zuoraUtility.QuoteWrapper2>();
    
   @future
    public static void isAfterInsertNew(Set<id> setQuoteChargId, Set<id> quoteIdSet){
      List<zqu__Quote__c> quoteList = new List<zqu__Quote__c>();
      List<zqu__QuoteCharge__c> newList=[Select id,zqu__Quote__c,zqu__ProductRatePlanCharge__r.CrmTaxCode__c from zqu__QuoteCharge__c  where id IN:setQuoteChargId];
      new QuoteTriggerHelper().updateTaxEstimates(newList);
      quoteList = [Select id,total_federal_taxes__c,total_state_and_local_taxes__c,
                            total_taxes__c from zqu__Quote__c where Id IN : quoteIdSet];
        for(zqu__Quote__c quote : quoteList){
            quote.Zuora_Calculating_tax__c = false;
        }
        update quoteList;
    }
    
   /* public void isAfterInsert(List<zqu__QuoteCharge__c> newList){
        updateTaxEstimates( newList);
    }    
    
    public void isAfterUpdate(List<zqu__QuoteCharge__c> newList){ 
        updateTaxEstimates( newList);
    } *

    private void updateTaxEstimates(List<zqu__QuoteCharge__c> newList ){
        List<zqu__QuoteCharge__c> quoteChargeList = new List<zqu__QuoteCharge__c>();
        try{
            for(zqu__QuoteCharge__c quoteCharge : newList){
                qChargeIdSet.add(quoteCharge.id);
                quoteIdSet.add(quoteCharge.zqu__Quote__c);
                system.debug('@@@@@@@@@@ '+ quoteIdSet);
            }
            quoteMap = new map<id,zqu__Quote__c>([Select id,total_federal_taxes__c,total_state_and_local_taxes__c,total_taxes__c from zqu__Quote__c where Id IN : quoteIdSet limit 50000]);
            zuoraUtility zuoraUtilityObj = new zuoraUtility();
            taxesMap = zuoraUtilityObj.getTaxList(quoteIdSet); 
            for(String quoteId : taxesMap.keySet()){
                zqu__Quote__c qObj = new zqu__Quote__c();
                qObj = quoteMap.get(quoteId);
                qObj.total_federal_taxes__c = taxesMap.get(quoteId).fedTotal;
                qObj.total_state_and_local_taxes__c = taxesMap.get(quoteId).StateTotal;
                quoteList.add(qObj);
            }
            update quoteList;
        }catch(Exception e ){
            System.debug('@@@@ Exception Occured : ' + e.getMessage());
        }    
    }*/
}