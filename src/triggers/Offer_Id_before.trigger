trigger Offer_Id_before on Offer_Id__c (before insert, before update) {
	/*if(trigger.isInsert){
		Map<Double, Id> mapTemp = new Map<Double, Id>();
		Map<Id, Offer_Id__c> signupPromotionMap = new Map<Id, Offer_Id__c>();
		for(Offer_Id__c pro: Trigger.new){  
			System.debug('## List_Order__c = ' + pro.List_Order__c + ',\n ## ProductName__r = ' + pro.ProductName__c + ',\n ### mapTemp.get(pro.List_Order__c) ' + mapTemp.get(pro.List_Order__c));
			if(mapTemp.get(pro.List_Order__c) != null && mapTemp.get(pro.List_Order__c) == pro.ProductName__c && pro.List_Order__c != NULL) {
				pro.List_Order__c.addError('This list order number is already in use by another promotion.'
                                 +'Please choose a different ordering number');
			} else {
				mapTemp.put(pro.List_Order__c, pro.ProductName__c);
				signupPromotionMap.put(pro.ProductName__c, pro);
			}
		}
		System.debug('## MAP = ' + mapTemp);
		if(mapTemp.size() != 0) {
			List<Offer_Id__c> existingPromotions = [SELECT Id, ProductName__c, List_Order__c FROM Offer_Id__c WHERE  List_Order__c IN:mapTemp.keySet()];
			// System.debug('## existingPromotions = ' + existingPromotions);
			for(Offer_Id__c orderObj: existingPromotions) {
				Id signupObj = mapTemp.get(orderObj.List_Order__c);
				System.debug('## signupObj= ' + signupObj +', ' +orderObj.ProductName__c+ ',\n ### ' +orderObj.List_Order__c );
				if(signupObj != null && signupObj == orderObj.ProductName__c && orderObj.List_Order__c != NULL) {
					signupPromotionMap.get(signupObj).List_Order__c.addError('This list order number is already in use by another promotion.'
                                 +'Please choose a different ordering number');
				} else {
					// System.debug('## signupObj.id = ' + (signupObj != null ? ''+signupObj : ' <empty>') + ',\n ### ' +orderObj.ProductName__c );
				}
			}
		}
		
		/*
		Map<Id, List<Decimal>> signupMap = new Map<Id, List<Decimal>>();
		List<Id> existingIds = new List<Id>();
   		for(Offer_Id__c pro: Trigger.new){   
   			List<Decimal> pList = signupMap.get(pro.ProductName__r.id);
   			if(pList != null) {
   				if(pList.contains(pro.List_Order__c)) {
   					existingIds.add(pro.Id);
   				} else {
   					pList.add(pro.List_Order__c);
   					signupMap.put(pro.ProductName__r.Id, pList);
   				}
   			} else {
   				List<Decimal> iniList = new List<Decimal>();
   				iniList.add(pro.List_Order__c);
   				signupMap.put(pro.ProductName__r, iniList);
   			}
   		}
   		if(existingIds.size() != 0) {
   			for(Id obj : existingIds) {
   				if(Trigger.newMap.get(obj) != null) {
   					Trigger.newMap.get(obj).addError('');
   				}
   			}
   		}
   		
   		List<Id> existingIdsnow = new List<Id>();
	   	if(signupMap.size() != 0) {
	   		List<Offer_Id__c> existingPromotions = [SELECT Id, ProductName__c, List_Order__c FROM Offer_Id__c WHERE  ProductName__c != NULL AND ProductName__c IN:signupMap.keySet()];
	   		for(Offer_Id__c orderList : existingPromotions) {
	   			List<Decimal> ids = signupMap(orderList.ProductName__r);
	   			if(ids.contains(orderList.List_Order__c)) {
	   				existingIdsnow.add(orderList.Id);
	   			}
	   		}
	   	}
   	
   		if(existingIdsnow.size() != 0) {
   			for(Id obj : existingIdsnow) {
   				if(Trigger.newMap.get(obj) != null) {
   					Trigger.newMap.get(obj).addError('');
   				}
   			}
   		}
   	*/
      /*  for(Offer_Id__c pro: Trigger.new){   
  
   		Set<id> pro_ids = trigger.newMap.keySet();    
  
   		Integer dupCheck = [SELECT count() FROM Offer_Id__c WHERE  ProductName__c != NULL AND ProductName__c=:pro.ProductName__c 
                       AND List_Order__c != NULL AND List_Order__c =: pro.List_Order__c];
   		if(dupCheck > 0){
      		pro.List_Order__c.addError('This list order number is already in use by another promotion.'
                                 +'Please choose a different ordering number');     
     	} 
    }*/
// }
  /*
  if(trigger.isUpdate){
    integer i=0;
   for(Offer_Id__c pro: Trigger.new){   
       if(Trigger.old[i].List_Order__c != Trigger.new[i].List_Order__c){
          Integer dupCheck = [SELECT count() FROM Offer_Id__c WHERE  ProductName__c != NULL AND ProductName__c=:pro.ProductName__c 
                       AND List_Order__c != NULL AND List_Order__c =: pro.List_Order__c];
          if(dupCheck > 0){
           pro.List_Order__c.addError('This list order number is already in use by another promotion.'
                                 +'Please choose a different ordering number');     
          }    
       
       } 
       i++;   
    }
  }*/
}