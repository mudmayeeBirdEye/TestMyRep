trigger LineItemsAfterTgr on Line_Item__c (before insert,before update,before delete,After Update,After delete,After Insert) {
    
    if(TriggerHandler.BY_PASS_LINEITEM_ON_INSERT || TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE){
        System.debug('### RETURNED FROM LINE ITEM INSERT/UPDATE TRG ###');
        return;
    } else {
        System.debug('### STILL CONTINUE FROM LINE ITEM INSERT/UPDATE TRG ###');
    }
    if(trigger.isBefore){   
            
        set<id> quoteIdSet = new set<id>();
        set<id> oppIdSet = new set<id>();
        
        String profileName ='';       
    	profileName = [Select id,Name from Profile where id=:userInfo.getProfileId()].Name;
            
        if(trigger.isInsert || trigger.isUpdate){
            for(Line_Item__c lineItemObj : trigger.new){
                if(lineItemObj.RC_Quote__c!=null){
                    quoteIdSet.add(lineItemObj.RC_Quote__c);
                }else if(lineItemObj.Opportunity__c!=null){
                    oppIdSet.add(lineItemObj.Opportunity__c);
                }
                /*if(Trigger.isInsert){                	
                	lineItemObj.Created_By_Profile__c = profileName;
                }*/                
            }
        }
        
        /*if(trigger.isDelete){
            for(Line_Item__c lineItemObj : trigger.old){
                if(lineItemObj.RC_Quote__c!=null){
                    quoteIdSet.add(lineItemObj.RC_Quote__c);
                }else if(lineItemObj.Opportunity__c!=null){
                    oppIdSet.add(lineItemObj.Opportunity__c);
                }
            }
        }
        
        map<id,RC_Quote__c> quoteMap = new Map<id,RC_Quote__c>([Select id,Total_Initial_Amount__c,Approved_Status__c,Initial_Total_Discount__c,Total_12M_Amount__c,Total_12M_Discount__c,Total_MRR__c,
                                                                (SELECT id,Discount__c,RC_Quote__c,Discount_Type__c,Effective_Discount__c,Effective_Price__c,List_Price__c,Approval_Required__c,Total_Price__c FROM Line_Items__r)
                                                                from RC_Quote__c where id in: quoteIdSet]);
        map<id,Opportunity> oppMap = new Map<id,Opportunity>([Select id,Total_Initial_Amount__c,Total_MRR__c,X12_Month_Booking__c,Amount,Probability,
                                                                (Select id From RC_Quotes__r where IsPrimary__c=true),(SELECT Id FROM Line_Items__r) 
                                                                from Opportunity where id in:oppIdSet]); */
        
      //  Set<Id> OpptyIdTempSet = new Set<Id>();
        if(trigger.isInsert || trigger.isUpdate){
            for(Line_Item__c lineItemObj : trigger.new){
                Double total12MonthsPrice = 0;
                Double totalInitialPrice = 0;
                Double totalMRRPrice = 0; 
                Double totalInitialDiscount = 0;
                Double total12MDiscount = 0;
                // Calculating 12M price
                if(lineItemObj.Charge_Term__c == 'Monthly - Contract' || lineItemObj.Charge_Term__c == 'Monthly'){
                    total12MonthsPrice = lineItemObj.Total_Price__c * 12;
                    total12MDiscount = (lineItemObj.Quantity__c)*(lineItemObj.Effective_Discount__c) * 12;
                }else{
                    total12MonthsPrice = lineItemObj.Total_Price__c;
                    total12MDiscount = (lineItemObj.Quantity__c)*(lineItemObj.Effective_Discount__c);
                }
                // Calculating Initial price
                totalInitialPrice = lineItemObj.Total_Price__c;
                totalInitialDiscount = (lineItemObj.Quantity__c)*(lineItemObj.Effective_Discount__c);
                // Calculating MRR price
                if(lineItemObj.Category__c == 'Service'){
                    if(lineItemObj.Charge_Term__c == 'Monthly - Contract' || lineItemObj.Charge_Term__c == 'Monthly'){
                        totalMRRPrice = lineItemObj.Total_Price__c;
                    }else{
                        totalMRRPrice = lineItemObj.Total_Price__c/12;
                    }   
                }
                //Adding values to line item fields
                lineItemObj.Total_12_Month_Price__c = total12MonthsPrice;
                lineItemObj.Total_Initial_Price__c = totalInitialPrice;
                lineItemObj.MRR__c = totalMRRPrice;
                lineItemObj.Total_12M_Discount__c = total12MDiscount;
                lineItemObj.Total_Initial_Discount__c = totalInitialDiscount;
                system.debug('=lineItemObj.Total_Initial_Price__c='+lineItemObj.Total_Initial_Price__c);
                system.debug('=lineItemObj.Total_12_Month_Price__c='+lineItemObj.Total_12_Month_Price__c);
                system.debug('=lineItemObj.MRR__c='+lineItemObj.MRR__c);
                if(trigger.isInsert){
                
                }else {
                    if(Trigger.oldMap!=null && Trigger.oldMap.get(lineItemObj.Id)!=null){
                        //System.debug('=Map Initial='+quoteMap.get(lineItemObj.RC_Quote__c).Total_Initial_Amount__c+'=Map 12M='+quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Amount__c+'=Map MRR='+quoteMap.get(lineItemObj.RC_Quote__c).Total_MRR__c);
                        System.debug('=Id='+lineItemObj.Id+'==Approval=='+Trigger.oldMap.get(lineItemObj.Id).Approval_Status__c+'=Max Discount='+lineItemObj.Max_Discount__c+'==Effective Dis=='+lineItemObj.Effective_Discount__c);
                        /*********Set Approval Status Field Of Line Item**********/
                        if(Trigger.oldMap.get(lineItemObj.Id).Approval_Status__c =='Approved'){                        	
                            // Need Approval if Quote has been previously Approved and a Sales Agent decreases the Quantity of an item which required Approval and 
                            // discount remains same
                            if(lineItemObj.Quantity__c < Trigger.oldMap.get(lineItemObj.Id).Quantity__c 
                                && lineItemObj.Effective_Discount__c == Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c){
                                lineItemObj.Approval_Required__c = true;
                                lineItemObj.Approval_Status__c = '';        
                            //No new Approval required if the Quantity increases and discount remains same.
                            }else if(lineItemObj.Quantity__c >= Trigger.oldMap.get(lineItemObj.Id).Quantity__c 
                                && lineItemObj.Effective_Discount__c == Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c){
                                lineItemObj.Approval_Required__c = false;
                            }
                            //Need Approval if Quote has previously been Approved and a Sales Agent increases the Discount of an item which required Approval
                            // and quantity remains same
                            if(lineItemObj.Effective_Discount__c > Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c
                                && lineItemObj.Quantity__c == Trigger.oldMap.get(lineItemObj.Id).Quantity__c){
                                lineItemObj.Approval_Required__c = true;
                                lineItemObj.Approval_Status__c = '';    
                            //No new Approval required if the Discount decreases and quantity remains same .            
                            }else if(lineItemObj.Effective_Discount__c <= Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c
                                        && lineItemObj.Quantity__c == Trigger.oldMap.get(lineItemObj.Id).Quantity__c){
                                lineItemObj.Approval_Required__c = false;
                            //If a Quote has been Approved and a Sales Agent modifies the Quantity and Discount of an item 
                            // which did not require Approval (and the new Discount is < Max Discount), no new Approval will be required.
                            }
                            if(!string.isBlank(profileName) && !profileName.startsWith('RC Partner')){
	                            if(lineItemObj.Effective_Discount__c != Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c
	                                        && lineItemObj.Quantity__c != Trigger.oldMap.get(lineItemObj.Id).Quantity__c
	                                        && lineItemObj.Max_Discount__c != NULL
	                                        && lineItemObj.Effective_Discount__c > lineItemObj.Max_Discount__c){
	                                lineItemObj.Approval_Required__c = true;
	                                lineItemObj.Approval_Status__c = '';    
	                            }
                            }else if(!string.isBlank(profileName) && profileName.startsWith('RC Partner')){
                            	if(lineItemObj.Effective_Discount__c != Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c
	                                        && lineItemObj.Quantity__c != Trigger.oldMap.get(lineItemObj.Id).Quantity__c
	                                        && lineItemObj.Effective_Discount__c != NULL
	                                        && lineItemObj.Effective_Discount__c > 0){
	                                lineItemObj.Approval_Required__c = true;
	                                lineItemObj.Approval_Status__c = '';    
	                            }
                            }
                            // Quantity and Discount remains same. then no approval required
                            system.debug('!!!!!!!!!!!!! 11 '+ lineItemObj.Effective_Discount__c);
                            system.debug('!!!!!!!!!!!!! 22 '+ Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c);
                            system.debug('!!!!!!!!!!!!! 33 '+ lineItemObj.Quantity__c);
                            system.debug('!!!!!!!!!!!!! 44 '+ Trigger.oldMap.get(lineItemObj.Id).Quantity__c);
                            if((Double.valueOf(lineItemObj.Effective_Discount__c) == Double.valueOf(Trigger.oldMap.get(lineItemObj.Id).Effective_Discount__c)) &&
                                     (Double.valueOf(lineItemObj.Quantity__c) == Double.valueOf(Trigger.oldMap.get(lineItemObj.Id).Quantity__c))){
                                lineItemObj.Approval_Required__c = false;
                            } 
                        }else if(Trigger.oldMap.get(lineItemObj.Id).Approval_Status__c =='' || Trigger.oldMap.get(lineItemObj.Id).Approval_Status__c == NULL){
                            if(!string.isBlank(profileName) && !profileName.startsWith('RC Partner')){
                            	if(lineItemObj.Max_Discount__c != NULL && lineItemObj.Effective_Discount__c > lineItemObj.Max_Discount__c){
                                	lineItemObj.Approval_Required__c = true;
                            	}
                            }else if(!string.isBlank(profileName) && profileName.startsWith('RC Partner')){
                            	if(lineItemObj.Effective_Discount__c != null && lineItemObj.Effective_Discount__c > 0){
                            		lineItemObj.Approval_Required__c = true;
                            	}
                            }
                        }else if(Trigger.oldMap.get(lineItemObj.Id).Approval_Status__c =='Rejected'){
                            if(!string.isBlank(profileName) && !profileName.startsWith('RC Partner')){
	                            if(lineItemObj.Max_Discount__c != NULL && lineItemObj.Effective_Discount__c > lineItemObj.Max_Discount__c){
	                                lineItemObj.Approval_Required__c = true;
	                                lineItemObj.Approval_Status__c = '';
	                            }
                            }else if(!string.isBlank(profileName) && profileName.startsWith('RC Partner')){
                            	if(lineItemObj.Effective_Discount__c != null && lineItemObj.Effective_Discount__c > 0){
                            		lineItemObj.Approval_Required__c = true;
                            		lineItemObj.Approval_Status__c = '';
                            	}
                            }
                        }
                        /************************************************/
                    }
                }
            }           
        }
        
      /*  if(trigger.isDelete){
            for(Line_Item__c lineItemObj : trigger.old){
                if(lineItemObj.RC_Quote__c!=null && quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
                    RC_Quote__c quoteObj = quoteMap.get(lineItemObj.RC_Quote__c);
                    quoteObj.Total_Initial_Amount__c = ((quoteObj.Total_Initial_Amount__c!=null ? quoteObj.Total_Initial_Amount__c : 0) 
                                                        -
                                                        (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
                    quoteObj.Total_12M_Amount__c = ((quoteObj.Total_12M_Amount__c!=null ? quoteObj.Total_12M_Amount__c : 0) 
                                                    -
                                                    (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
                    quoteObj.Total_MRR__c = ((quoteObj.Total_MRR__c!=null ? quoteObj.Total_MRR__c : 0) 
                                             - 
                                            (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
                    quoteObj.Total_12M_Discount__c = ((quoteObj.Total_12M_Discount__c!=null ? quoteObj.Total_12M_Discount__c : 0) 
                                                      - 
                                                     (lineItemObj.Total_12M_Discount__c!=null ? lineItemObj.Total_12M_Discount__c : 0));
                    quoteObj.Initial_Total_Discount__c = ((quoteObj.Initial_Total_Discount__c!=null ? quoteObj.Initial_Total_Discount__c : 0) 
                                                        - 
                                                        (lineItemObj.Total_Initial_Discount__c!=null ? lineItemObj.Total_Initial_Discount__c : 0));
                                                        
                }else if(lineItemObj.Opportunity__c!=null && oppMap!=null && oppMap.get(lineItemObj.Opportunity__c)!=null){
                    if(oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r == null || oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r.size() == 0){
                        Opportunity oppObj = oppMap.get(lineItemObj.Opportunity__c);
                        oppObj.Total_Initial_Amount__c = ((oppObj.Total_Initial_Amount__c!=null ? oppObj.Total_Initial_Amount__c : 0) 
                                                            - 
                                                            (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
                        oppObj.X12_Month_Booking__c = ((oppObj.X12_Month_Booking__c!=null ? oppObj.X12_Month_Booking__c : 0) 
                                                            - 
                                                        (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
                        oppObj.Total_MRR__c = ((oppObj.Total_MRR__c!=null ? oppObj.Total_MRR__c : 0) 
                                                            - 
                                                 (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
                        if(oppObj.Probability != null ){                         
                            oppObj.Amount = ((oppObj.X12_Month_Booking__c * oppObj.Probability)/100).setScale(2);
                        }
                    }                       
                }
            }
        } 
        
        try{
            if(oppMap!=null && oppMap.size() > 0){
                update oppMap.values();
            }
        
            if(quoteMap!=null && quoteMap.size() > 0){          
                update quoteMap.values();           
            }   
        }catch(System.DmlException e){          
            //Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.error,e.getDmlMessage(0)) );
            if(Trigger.isDelete){
            	Trigger.old[0].addError(e.getDmlMessage(0)); 
            }else{
            	Trigger.new[0].addError(e.getDmlMessage(0));
            } 
        } */  
    }
    
    // After Trigger
    if(Trigger.isAfter){
        set<id> quoteIdSet = new set<id>();
        set<id> oppIdSet = new set<id>();
        
        String profileName ='';       
    	profileName = [Select id,Name from Profile where id=:userInfo.getProfileId()].Name;
            
        if(trigger.isInsert || trigger.isUpdate || trigger.isDelete){
            List<Line_Item__c> tempList = (Trigger.isDelete ? trigger.old : trigger.new);
            for(Line_Item__c lineItemObj : tempList){
                if(lineItemObj.RC_Quote__c!=null){
                    quoteIdSet.add(lineItemObj.RC_Quote__c);
                }else if(lineItemObj.Opportunity__c!=null){
                    oppIdSet.add(lineItemObj.Opportunity__c);
                }
            }
        }
        
		map<id,RC_Quote__c> quoteMap = new Map<id,RC_Quote__c>([Select id,Special_Terms_and_Notes__c,Total_Initial_Amount__c,Approved_Status__c,Initial_Total_Discount__c,Total_12M_Amount__c,Total_12M_Discount__c,Total_MRR__c,
                                                                (SELECT id,Discount__c,RC_Quote__c,Discount_Type__c,Effective_Discount__c,Effective_Price__c,List_Price__c,Approval_Required__c,Total_Price__c FROM Line_Items__r)
                                                                from RC_Quote__c where id in: quoteIdSet]);
        map<id,Opportunity> oppMap = new Map<id,Opportunity>([Select id,Total_Initial_Amount__c,Total_MRR__c,X12_Month_Booking__c,Amount,Probability,
                                                                (Select id From RC_Quotes__r where IsPrimary__c=true),(SELECT Id FROM Line_Items__r) 
                                                                from Opportunity where id in:oppIdSet]);
        
        Set<Id> OpptyIdTempSet = new Set<Id>();
        
        if(Trigger.isUpdate || Trigger.isInsert){
            for(Line_Item__c lineItemObj : Trigger.new){
            	if(Trigger.isInsert){
                    system.debug('=lineItemObj.RC_Quote__c='+lineItemObj.RC_Quote__c+'==>'+quoteMap.get(lineItemObj.RC_Quote__c));
                    if(lineItemObj.RC_Quote__c!=null && quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
                        RC_Quote__c quoteObj = quoteMap.get(lineItemObj.RC_Quote__c);
                        quoteObj.Total_Initial_Amount__c = ((quoteObj.Total_Initial_Amount__c!=null ? quoteObj.Total_Initial_Amount__c : 0) 
                                                            + 
                                                            (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
                        quoteObj.Total_12M_Amount__c = ((quoteObj.Total_12M_Amount__c!=null ? quoteObj.Total_12M_Amount__c : 0) 
                                                            + 
                                                        (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
                        quoteObj.Total_MRR__c = ((quoteObj.Total_MRR__c!=null ? quoteObj.Total_MRR__c : 0) 
                                                            + 
                                                 (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
                        quoteObj.Total_12M_Discount__c = ((quoteObj.Total_12M_Discount__c!=null ? quoteObj.Total_12M_Discount__c : 0) 
                                                            + 
                                                 (lineItemObj.Total_12M_Discount__c!=null ? lineItemObj.Total_12M_Discount__c : 0));
                        quoteObj.Initial_Total_Discount__c = ((quoteObj.Initial_Total_Discount__c!=null ? quoteObj.Initial_Total_Discount__c : 0) 
                                                            + 
                                                 (lineItemObj.Total_Initial_Discount__c!=null ? lineItemObj.Total_Initial_Discount__c : 0));
                        /*quoteObj.Total_Calculated_Amount__c = ((quoteObj.Total_Calculated_Amount__c!=null ? quoteObj.Total_Calculated_Amount__c : 0) 
                                                            + 
                                                 (lineItemObj.Total_Price__c!=null ? lineItemObj.Total_Price__c : 0));*/
                                                 
                    } else if(lineItemObj.Opportunity__c!=null && oppMap!=null && oppMap.get(lineItemObj.Opportunity__c)!=null){
                        if(oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r == null || oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r.size() == 0){
                            Opportunity oppObj = oppMap.get(lineItemObj.Opportunity__c);
                            System.debug('&&&&&&&&&&&&&&&&&&7 '+ oppObj.line_items__r);
                            if((oppObj.line_items__r == NULL || oppObj.line_items__r.size() == 0) && !OpptyIdTempSet.contains(oppObj.Id)){
                                oppObj.Total_Initial_Amount__c =null;
                                oppObj.X12_Month_Booking__c =null;
                                oppObj.Total_MRR__c =null;
                                oppObj.Amount =null;
                                OpptyIdTempSet.add(oppObj.Id);
                            }
                            oppObj.Total_Initial_Amount__c = ((oppObj.Total_Initial_Amount__c!=null ? oppObj.Total_Initial_Amount__c : 0) 
                                                                + 
                                                                (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
                            oppObj.X12_Month_Booking__c = ((oppObj.X12_Month_Booking__c!=null ? oppObj.X12_Month_Booking__c : 0) 
                                                                + 
                                                            (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
                            oppObj.Total_MRR__c = ((oppObj.Total_MRR__c!=null ? oppObj.Total_MRR__c : 0) 
                                                                + 
                                                     (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
                            if(oppObj.Probability != null ){                         
                                oppObj.Amount = ((oppObj.X12_Month_Booking__c * oppObj.Probability)/100).setScale(2);                    
                            }
                            /*oppObj.Total_Calculated_Amount__c = ((oppObj.Total_Calculated_Amount__c!=null ? oppObj.Total_Calculated_Amount__c : 0) 
                                                                + 
                                                     (lineItemObj.Total_Price__c!=null ? lineItemObj.Total_Price__c : 0));*/
                        }                       
                    }
                
            	}else {
            		if(Trigger.oldMap!=null && Trigger.oldMap.get(lineItemObj.Id)!=null){
            			
                        Decimal oldInitialPrice = 0;
                        Decimal old12MPrice = 0;
                        Decimal oldMRRPrice = 0;
                        Decimal oldInitialDiscount = 0;
                        Decimal old12MDiscount = 0;
                        Decimal oldTotalAmount = 0;
                        if(lineItemObj.RC_Quote__c == Trigger.oldMap.get(lineItemObj.Id).RC_Quote__c){
                            oldInitialPrice = (Trigger.oldMap.get(lineItemObj.Id).Total_Initial_Price__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).Total_Initial_Price__c );
                            old12MPrice = (Trigger.oldMap.get(lineItemObj.Id).Total_12_Month_Price__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).Total_12_Month_Price__c );
                            oldMRRPrice = (Trigger.oldMap.get(lineItemObj.Id).MRR__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).MRR__c );
                            oldInitialDiscount = (Trigger.oldMap.get(lineItemObj.Id).Total_Initial_Discount__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).Total_Initial_Discount__c );
                            old12MDiscount = (Trigger.oldMap.get(lineItemObj.Id).Total_12M_Discount__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).Total_12M_Discount__c );
                            oldTotalAmount = (Trigger.oldMap.get(lineItemObj.Id).Total_Price__c == NULL ? 0:Trigger.oldMap.get(lineItemObj.Id).Total_Price__c );
                        }
                        
                        System.debug('=oldInitialPrice='+oldInitialPrice+'=old12MPrice='+old12MPrice+'=oldMRRPrice='+oldMRRPrice);
                        if(quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
                            Double oldInitialOfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Total_Initial_Amount__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Total_Initial_Amount__c);
                            Double old12MOfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Amount__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Amount__c);
                            Double oldMRROfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Total_MRR__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Total_MRR__c);
                            Double oldIntialDiscountOfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Initial_Total_Discount__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Initial_Total_Discount__c);
                            Double old12MDiscountOfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Discount__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Discount__c);
                            //Double oldTotalAmountOfQuote = (quoteMap.get(lineItemObj.RC_Quote__c).Total_Calculated_Amount__c == NULL ? 0:quoteMap.get(lineItemObj.RC_Quote__c).Total_Calculated_Amount__c);
                            System.debug('=oldInitialOfQuote='+oldInitialOfQuote+'=old12MOfQuote='+old12MOfQuote+'=oldMRROfQuote='+oldMRROfQuote);
                            system.debug('=lineItemObj.Total_Initial_Price__c='+lineItemObj.Total_Initial_Price__c);
                            if(oldInitialOfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_Initial_Amount__c = (lineItemObj.Total_Initial_Price__c - oldInitialPrice) + oldInitialOfQuote; 
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_Initial_Amount__c = lineItemObj.Total_Initial_Price__c;
                            }
                            if(old12MOfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Amount__c = (lineItemObj.Total_12_Month_Price__c - old12MPrice) + old12MOfQuote;    
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Amount__c = lineItemObj.Total_12_Month_Price__c;
                            }
                            if(oldMRROfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_MRR__c = (lineItemObj.MRR__c  - oldMRRPrice) + oldMRROfQuote;
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_MRR__c = lineItemObj.MRR__c;
                            }                           
                            if(old12MDiscountOfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Discount__c = (lineItemObj.Total_12M_Discount__c  - old12MDiscount) + old12MDiscountOfQuote;
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_12M_Discount__c = lineItemObj.Total_12M_Discount__c;
                            }
                            if(oldIntialDiscountOfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Initial_Total_Discount__c = (lineItemObj.Total_Initial_Discount__c  - oldInitialDiscount) + oldIntialDiscountOfQuote;
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Initial_Total_Discount__c = lineItemObj.Total_Initial_Discount__c;
                            }
                            /*if(oldTotalAmountOfQuote != 0){
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_Calculated_Amount__c = (lineItemObj.Total_Price__c  - oldTotalAmount) + oldTotalAmountOfQuote;
                            }else{
                                quoteMap.get(lineItemObj.RC_Quote__c).Total_Calculated_Amount__c = lineItemObj.Total_Price__c;
                            }*/
                        } else if(oppMap!=null && oppMap.get(lineItemObj.Opportunity__c)!=null){
                            if(oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r == null || oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r.size() == 0){
                                Double oldInitialOfOpp = (oppMap.get(lineItemObj.Opportunity__c).Total_Initial_Amount__c == NULL ? 0:oppMap.get(lineItemObj.Opportunity__c).Total_Initial_Amount__c);
                                Double old12MOfOpp = (oppMap.get(lineItemObj.Opportunity__c).X12_Month_Booking__c == NULL ? 0:oppMap.get(lineItemObj.Opportunity__c).X12_Month_Booking__c);
                                Double oldMRROfOpp = (oppMap.get(lineItemObj.Opportunity__c).Total_MRR__c == NULL ? 0:oppMap.get(lineItemObj.Opportunity__c).Total_MRR__c);
                                //Double oldTotalAmountOfOpp = (oppMap.get(lineItemObj.Opportunity__c).Total_Calculated_Amount__c == NULL ? 0:oppMap.get(lineItemObj.Opportunity__c).Total_Calculated_Amount__c);
                                
                                if(oldInitialOfOpp != 0){
                                    oppMap.get(lineItemObj.Opportunity__c).Total_Initial_Amount__c = (lineItemObj.Total_Initial_Price__c - oldInitialPrice) + oldInitialOfOpp;  
                                }else{
                                    oppMap.get(lineItemObj.Opportunity__c).Total_Initial_Amount__c = lineItemObj.Total_Initial_Price__c;
                                }
                                if(old12MOfOpp != 0){
                                    oppMap.get(lineItemObj.Opportunity__c).X12_Month_Booking__c = (lineItemObj.Total_12_Month_Price__c - old12MPrice) + old12MOfOpp;    
                                }else{
                                    oppMap.get(lineItemObj.Opportunity__c).X12_Month_Booking__c = lineItemObj.Total_12_Month_Price__c;  
                                }
                                if(oldMRROfOpp != 0){
                                    oppMap.get(lineItemObj.Opportunity__c).Total_MRR__c = (lineItemObj.MRR__c  - oldMRRPrice) + oldMRROfOpp;
                                }else{
                                    oppMap.get(lineItemObj.Opportunity__c).Total_MRR__c = lineItemObj.MRR__c;
                                }
                                if(oppMap.get(lineItemObj.Opportunity__c).Probability != null ){                         
                                    oppMap.get(lineItemObj.Opportunity__c).Amount = ((oppMap.get(lineItemObj.Opportunity__c).X12_Month_Booking__c * oppMap.get(lineItemObj.Opportunity__c).Probability)/100).setScale(2);                    
                                }
                            }
                        }
            		}
            	}
            }	
        }
        	
        if(Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete){
        	List<Line_Item__c> lineItemList = new List<Line_Item__c>();
        	if(Trigger.isDelete){
        		lineItemList = Trigger.old;
        	}else{
        		lineItemList = Trigger.new;
        	}
        	
            for(Line_Item__c lineItemObj : lineItemList){   
            	if(Trigger.isDelete){
	                if(lineItemObj.RC_Quote__c!=null && quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
	                    RC_Quote__c quoteObj = quoteMap.get(lineItemObj.RC_Quote__c);
	                    quoteObj.Total_Initial_Amount__c = ((quoteObj.Total_Initial_Amount__c!=null ? quoteObj.Total_Initial_Amount__c : 0) 
	                                                        -
	                                                        (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
	                    quoteObj.Total_12M_Amount__c = ((quoteObj.Total_12M_Amount__c!=null ? quoteObj.Total_12M_Amount__c : 0) 
	                                                    -
	                                                    (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
	                    quoteObj.Total_MRR__c = ((quoteObj.Total_MRR__c!=null ? quoteObj.Total_MRR__c : 0) 
	                                             - 
	                                            (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
	                    quoteObj.Total_12M_Discount__c = ((quoteObj.Total_12M_Discount__c!=null ? quoteObj.Total_12M_Discount__c : 0) 
	                                                      - 
	                                                     (lineItemObj.Total_12M_Discount__c!=null ? lineItemObj.Total_12M_Discount__c : 0));
	                    quoteObj.Initial_Total_Discount__c = ((quoteObj.Initial_Total_Discount__c!=null ? quoteObj.Initial_Total_Discount__c : 0) 
	                                                        - 
	                                                        (lineItemObj.Total_Initial_Discount__c!=null ? lineItemObj.Total_Initial_Discount__c : 0));
	                                                        
	                }else if(lineItemObj.Opportunity__c!=null && oppMap!=null && oppMap.get(lineItemObj.Opportunity__c)!=null){
	                    if(oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r == null || oppMap.get(lineItemObj.Opportunity__c).RC_Quotes__r.size() == 0){
	                        Opportunity oppObj = oppMap.get(lineItemObj.Opportunity__c);
	                        oppObj.Total_Initial_Amount__c = ((oppObj.Total_Initial_Amount__c!=null ? oppObj.Total_Initial_Amount__c : 0) 
	                                                            - 
	                                                            (lineItemObj.Total_Initial_Price__c!=null ? lineItemObj.Total_Initial_Price__c : 0));
	                        oppObj.X12_Month_Booking__c = ((oppObj.X12_Month_Booking__c!=null ? oppObj.X12_Month_Booking__c : 0) 
	                                                            - 
	                                                        (lineItemObj.Total_12_Month_Price__c!=null ? lineItemObj.Total_12_Month_Price__c : 0));
	                        oppObj.Total_MRR__c = ((oppObj.Total_MRR__c!=null ? oppObj.Total_MRR__c : 0) 
	                                                            - 
	                                                 (lineItemObj.MRR__c!=null ? lineItemObj.MRR__c : 0));
	                        if(oppObj.Probability != null ){                         
	                            oppObj.Amount = ((oppObj.X12_Month_Booking__c * oppObj.Probability)/100).setScale(2);
	                        }
	                    }                       
	                }
            	}
                /***************Set Approval required Field On Quote*************/
                Boolean approvalRequiredVar = false;
                if(quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
                    if(lineItemObj.Approval_Required__c==true && !Trigger.isDelete){
                        approvalRequiredVar = true;
                    }
                    if(quoteMap.get(lineItemObj.RC_Quote__c).Line_Items__r!=null && !approvalRequiredVar){
                        for(Line_Item__c lineObj : quoteMap.get(lineItemObj.RC_Quote__c).Line_Items__r){
                            if(lineObj.Approval_Required__c==true){                    
                                approvalRequiredVar = true;
                                break;
                            }
                        }
                    }
                    if(string.isBlank(quoteMap.get(lineItemObj.RC_Quote__c).Special_Terms_and_Notes__c) == false){
                    	approvalRequiredVar = true;
                    }
                    system.debug('@@@@@@ &&&&&&&&&&&&&&& '+approvalRequiredVar + ' @@@@@@@@@ '+ String.valueOf(quoteMap.get(lineItemObj.RC_Quote__c).Special_Terms_and_Notes__c));
                    system.debug('@@@@@@ &&&&&&&&&&&&&&& '+approvalRequiredVar + ' @@@@@@@@@ '+ quoteMap.get(lineItemObj.RC_Quote__c).Id);
                    if(approvalRequiredVar){                        
                        if(quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c!='Not Submitted' && 
                            quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c!= 'Pending Approval'){
                            
                            quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Required';  
                        }else{
                            if(quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c == ''){
                                quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Not Required';  
                            }
                        }
                    }else if(string.isBlank(quoteMap.get(lineItemObj.RC_Quote__c).Special_Terms_and_Notes__c)){
                        quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Not Required';
                    }
                }
                /****************************************************************/
            }
        }
        try{
            if(oppMap!=null && oppMap.size() > 0){
                update oppMap.values();
            }
        
            if(quoteMap!=null && quoteMap.size() > 0){          
                update quoteMap.values();           
            }   
        }catch(System.DmlException e){          
            //Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.error,e.getDmlMessage(0)) );
            if(Trigger.isDelete){
            	Trigger.old[0].addError(e.getDmlMessage(0)); 
            }else{
            	Trigger.new[0].addError(e.getDmlMessage(0));
            } 
        }   
        
        
    	/*quoteIdSet = new set<id>();
            
        if(Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete){
        	List<Line_Item__c> lineItemList = new List<Line_Item__c>();
        	if(Trigger.isDelete){
        		lineItemList = Trigger.old;
        	}else{
        		lineItemList = Trigger.new;
        	}
            for(Line_Item__c lineItemObj : lineItemList){ 
                if(lineItemObj.RC_Quote__c!=null){
                    quoteIdSet.add(lineItemObj.RC_Quote__c);
                }
            }
        }
        
        quoteMap = new Map<id,RC_Quote__c>([Select id,Special_Terms_and_Notes__c,Total_Initial_Amount__c,Approved_Status__c,Initial_Total_Discount__c,Total_12M_Amount__c,Total_12M_Discount__c,Total_MRR__c,
                                                                (SELECT id,Discount__c,RC_Quote__c,Discount_Type__c,Effective_Discount__c,Effective_Price__c,List_Price__c,Approval_Required__c FROM Line_Items__r)
                                                                from RC_Quote__c where id in: quoteIdSet]);
        if(Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete){
        	List<Line_Item__c> lineItemList = new List<Line_Item__c>();
        	if(Trigger.isDelete){
        		lineItemList = Trigger.old;
        	}else{
        		lineItemList = Trigger.new;
        	}
            for(Line_Item__c lineItemObj : lineItemList){        	
                /***************Set Approval required Field On Quote*************
                Boolean approvalRequiredVar = false;
                if(quoteMap!=null && quoteMap.get(lineItemObj.RC_Quote__c)!=null){
                    if(lineItemObj.Approval_Required__c==true && !Trigger.isDelete){
                        approvalRequiredVar = true;
                    }
                    if(quoteMap.get(lineItemObj.RC_Quote__c).Line_Items__r!=null && !approvalRequiredVar){
                        for(Line_Item__c lineObj : quoteMap.get(lineItemObj.RC_Quote__c).Line_Items__r){
                            if(lineObj.Approval_Required__c==true ){                    
                                approvalRequiredVar = true;
                                break;
                            }
                        }
                    }
                    system.debug('@@@@@@ &&&&&&&&&&&&&&& '+approvalRequiredVar);
                    if(approvalRequiredVar){                        
                        if(quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c!='Not Submitted' && 
                            quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c!= 'Pending Approval'){
                            
                            quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Required';  
                        }else{
                            if(quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c == ''){
                                quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Not Required';  
                            }
                        }
                    }else if(string.isBlank(quoteMap.get(lineItemObj.RC_Quote__c).Special_Terms_and_Notes__c)){
                        quoteMap.get(lineItemObj.RC_Quote__c).Approved_Status__c = 'Not Required';
                    }
                }
                /***************************************************************
            }
        }
        try{
            if(quoteMap!=null && quoteMap.size() > 0){          
                update quoteMap.values();           
            }
        }catch(System.DmlException e){          
            Trigger.new[0].addError(e.getDmlMessage(0)); 
        }  */ 
    }
}