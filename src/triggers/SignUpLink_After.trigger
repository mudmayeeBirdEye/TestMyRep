trigger SignUpLink_After on SignUpLink__c (after insert) {
	/*
 	List<Offer_Id__c> promotions = new List<Offer_Id__c>();
    for(SignUpLink__c signupLink : trigger.new) {
        Offer_Id__c promotion = new Offer_Id__c();
        promotion.ProductName__c = signupLink.Id;
        promotion.Description__c = 'No Discount';
        promotion.List_Order__c = 0;
        promotions.add(promotion);
    }
   
    if(promotions.size() != 0)
        insert promotions;
        */
}