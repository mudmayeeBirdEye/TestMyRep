trigger DealRegistration on VAR_Deal_Registration__c (before insert,after insert,before update,after update) {

 if(trigger.isInsert){
		if(trigger.isBefore){
			    if(trigger.isInsert){
			         Integer totalRegistration=0;
			        
			         User objUser=null;
			         for(User objUs:[Select Contact.Account.High_Volume_Deal_Registration__c,Contact.Account.Partner_id__c,Contact.AccountId from User where id=:UserInfo.getUserId()]){
			          if(objUs!=null){
			            objUser=objUs;
			          }
			        }
			        Integer iMaxLimit=0;
                    if(objUser.Contact.Account.Partner_id__c!=null){
                    
                      if(objUser.Contact.Account.High_Volume_Deal_Registration__c){
                          iMaxLimit=1000;
                      }else{
                          iMaxLimit=200;
                      }
                    } 
			        
			        if(objUser.Contact.Account.Partner_id__c!=null){
			           for(AggregateResult objAggregateResult:[Select count(id) total from VAR_Deal_Registration__c where
			                                                    Partner_Id__c=:objUser.Contact.Account.Partner_id__c and
			                                                    (Registration_Status__c='Approved' OR  Registration_Status__c='Pending')
			                                                     and Is_Expired__c='No']){
			                
			                totalRegistration=(Integer)objAggregateResult.get('total');
			            }
			             if(totalRegistration<iMaxLimit){
			                   Map<String,String> mapExistingEmail=new Map<String,String>();
			                   Set <String> setEmailId=new Set<String>();
			                    
			                    setEmailId.add(trigger.new[0].Email_1__c);
			                    if(trigger.new[0].Email_2__c!=null && trigger.new[0].Email_2__c!=''){
			                        setEmailId.add(trigger.new[0].Email_2__c);
			                     }
			                    if(trigger.new[0].Email_3__c!=null && trigger.new[0].Email_3__c!=''){
			                         setEmailId.add(trigger.new[0].Email_3__c);
			                    }
				                if(trigger.new[0].Email_4__c!=null && trigger.new[0].Email_4__c!=''){
				                      setEmailId.add(trigger.new[0].Email_4__c);
				                }
				                if(trigger.new[0].Email_5__c!=null && trigger.new[0].Email_5__c!=''){  
				                     setEmailId.add(trigger.new[0].Email_5__c);
				                } 
			                   
			                   for(VAR_Deal_Registration__c obj:[Select Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c
			                                                       from VAR_Deal_Registration__c where 
			                                                       ((Email_1__c IN :setEmailId) OR (Email_2__c IN :setEmailId) OR (Email_3__c IN :setEmailId)
			                                                         OR (Email_4__c IN :setEmailId)  OR (Email_5__c IN :setEmailId) )
			                                                         AND Registration_Status__c !='Rejected' and Is_Expired__c!='Yes' ]){
			                    
			                    mapExistingEmail.put(obj.Email_1__c,obj.Email_1__c);
			                    
			                     mapExistingEmail.put(obj.Email_2__c,obj.Email_2__c);
			                     mapExistingEmail.put(obj.Email_3__c,obj.Email_3__c);
			                     mapExistingEmail.put(obj.Email_4__c,obj.Email_4__c);
			                     mapExistingEmail.put(obj.Email_5__c,obj.Email_5__c);
			                 }
			                
			                    if(trigger.new[0].Email_1__c!=null && mapExistingEmail.get(trigger.new[0].Email_1__c)!=null){
			                       trigger.new[0].Email_1__c.addError('This email already Exists!');
			                    }
			                    if(trigger.new[0].Email_2__c!=null && mapExistingEmail.get(trigger.new[0].Email_2__c)!=null){
			                       trigger.new[0].Email_2__c.addError('This email already Exists!');
			                    }   
			                    if(trigger.new[0].Email_3__c!=null && mapExistingEmail.get(trigger.new[0].Email_3__c)!=null){
			                       trigger.new[0].Email_3__c.addError('This email already Exists!');
			                    }   
			                    if(trigger.new[0].Email_4__c!=null && mapExistingEmail.get(trigger.new[0].Email_4__c)!=null){
			                       trigger.new[0].Email_4__c.addError('This email already Exists!');
			                    }   
			                    if(trigger.new[0].Email_5__c!=null && mapExistingEmail.get(trigger.new[0].Email_5__c)!=null){
			                       trigger.new[0].Email_5__c.addError('This email already Exists!');
			                    }   
			       
			              if(objUser!=null){
			                 trigger.new[0].Partner_Id__c=objUser.Contact.Account.Partner_id__c;
			                 trigger.new[0].Partner_Account_Id__c=objUser.Contact.AccountId;
			              }
			       }else{
			            trigger.new[0].addError('Your registration limit (approved, pending approval & not expired) cannot exceed '+totalRegistration+'!');
			           }
			  }else{
			      trigger.new[0].addError('You are not authorized partner');
			    }
		  }
		}
		if(trigger.isAfter){
		     if(trigger.isInsert){
		            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
		            req1.setComments('Submitting request for approval.');
		            req1.setObjectId(trigger.new[0].id);
		            Approval.ProcessResult result = Approval.process(req1);
		         }
		  }
  }
  if(trigger.isUpdate){
  
  	 if( !( trigger.new[0].Registration_Status__c == 'Approved'  
			  			&& ( trigger.new[0].Deal_Closed__c != trigger.old[0].Deal_Closed__c 
			  				|| trigger.new[0].DealRegistrationAccount__c != trigger.old[0].DealRegistrationAccount__c)
			  				)
		  			&& !DealRigstrationHelper.IsChanged( trigger.new[0] , trigger.old[0] ) ){
	  	
	  	if(trigger.new[0].Registration_Status__c!='Rejected' && 
		   trigger.new[0].Registration_Status__c==trigger.old[0].Registration_Status__c
		   && trigger.new[0].Extension_Status__c!='Pending' && 
		   trigger.new[0].Extension_Status__c== trigger.old[0].Extension_Status__c ){
		   		 trigger.new[0].addError('You cannot edit this record because this record status is not Rejected!');
		  }
		  
	}
		if(trigger.new[0].Registration_Status__c!='Approved' 
		   && trigger.new[0].Registration_Status__c=='Rejected'
		   && trigger.old[0].Registration_Status__c!='Pending'){//If Request is not Approved
		   
			   if(trigger.isBefore){
				        if(trigger.isUpdate)
				         {
				             Integer totalRegistration=0;
				             if(trigger.old[0].Registration_Status__c!='Pending')
				             {
				                 trigger.new[0].Registration_Status__c='New';
				              }
				              Integer iMaxLimit=0;
                              for(Account objAccount:[Select High_Volume_Deal_Registration__c from Account where id=:trigger.new[0].Partner_Account_Id__c ]){
                                 if(objAccount.High_Volume_Deal_Registration__c){
	                                  iMaxLimit=1000;
	                              }else{
	                                  iMaxLimit=200;
	                              }
                              }
					          for(AggregateResult objAggregateResult:[Select count(id) total from VAR_Deal_Registration__c where
					                                                 Partner_Id__c=: trigger.new[0].Partner_Id__c and
					                                                (Registration_Status__c='Approved' OR  Registration_Status__c='Pending')
					                                                 and Is_Expired__c='No']){
					                    totalRegistration=(Integer)objAggregateResult.get('total');
					                }
					               if(totalRegistration<iMaxLimit){ 
					                      
					                    Map<String,String> mapExistingEmail=new Map<String,String>();
					                     Set <String> setEmailId=new Set<String>();
		                    
						                    setEmailId.add(trigger.new[0].Email_1__c);
						                    if(trigger.new[0].Email_2__c!=null && trigger.new[0].Email_2__c!=''){
						                        setEmailId.add(trigger.new[0].Email_2__c);
						                     }
						                    if(trigger.new[0].Email_3__c!=null && trigger.new[0].Email_3__c!=''){
						                         setEmailId.add(trigger.new[0].Email_3__c);
						                    }
							                if(trigger.new[0].Email_4__c!=null && trigger.new[0].Email_4__c!=''){
							                      setEmailId.add(trigger.new[0].Email_4__c);
							                }
							                if(trigger.new[0].Email_5__c!=null && trigger.new[0].Email_5__c!=''){  
							                     setEmailId.add(trigger.new[0].Email_5__c);
							                } 
					                    for(VAR_Deal_Registration__c obj:[Select Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c
					                                                            from VAR_Deal_Registration__c where 
					                                                            ((Email_1__c IN :setEmailId) OR (Email_2__c IN :setEmailId) OR (Email_3__c IN :setEmailId)
		                                                                           OR (Email_4__c IN :setEmailId)  OR (Email_5__c IN :setEmailId) )
					                                                               AND Registration_Status__c !='Rejected'  and Is_Expired__c !='Yes' 
					                                                               AND id!=:trigger.new[0].id]){
					                        
					                        mapExistingEmail.put(obj.Email_1__c,obj.Email_1__c);
					                         mapExistingEmail.put(obj.Email_2__c,obj.Email_2__c);
					                          mapExistingEmail.put(obj.Email_3__c,obj.Email_3__c);
					                           mapExistingEmail.put(obj.Email_4__c,obj.Email_4__c);
					                            mapExistingEmail.put(obj.Email_5__c,obj.Email_5__c);
					                                 
					                        }
					                        if(trigger.new[0].Email_1__c!=null && mapExistingEmail.get(trigger.new[0].Email_1__c)!=null){
					                           trigger.new[0].Email_1__c.addError('This email already Exists!');
					                        }
					                         if(trigger.new[0].Email_2__c!=null && mapExistingEmail.get(trigger.new[0].Email_2__c)!=null){
					                           trigger.new[0].Email_2__c.addError('This email already Exists!');
					                        }   
					                         if(trigger.new[0].Email_3__c!=null && mapExistingEmail.get(trigger.new[0].Email_3__c)!=null){
					                           trigger.new[0].Email_3__c.addError('This email already Exists!');
					                        }   
					                         if(trigger.new[0].Email_4__c!=null && mapExistingEmail.get(trigger.new[0].Email_4__c)!=null){
					                           trigger.new[0].Email_4__c.addError('This email already Exists!');
					                        }   
					                         if(trigger.new[0].Email_5__c!=null && mapExistingEmail.get(trigger.new[0].Email_5__c)!=null){
					                           trigger.new[0].Email_5__c.addError('This email already Exists!');
					                        }   
						    }else{
						    	  trigger.new[0].addError('Your registration limit (approved, pending approval & not expired) cannot exceed '+totalRegistration+'!');
						     }
				         }
			    }
		     }
		
	    if(trigger.isAfter){
	         if(trigger.isUpdate && trigger.new[0].Registration_Status__c=='New'){
	                Approval.ProcessSubmitRequest objApprovalReq = new Approval.ProcessSubmitRequest();
	                objApprovalReq.setComments('ReSubmitting request for approval.');
	                objApprovalReq.setObjectId(trigger.new[0].id);
	                Approval.ProcessResult result = Approval.process(objApprovalReq);
	             }
	       }
    }
    
}