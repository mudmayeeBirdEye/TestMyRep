/*************************************************
Trigger on EmailMessage object
After Delete: Prevents non-admin user from deleting EmailMessage.
/************************************************/

trigger EmailMessageBefore on EmailMessage (before delete) {
   
   // Get the current user's profile name
    Profile objProfile =null;
    for(Profile objProf:[Select p.Name From Profile p where id=:UserInfo.getProfileId()]){
      if(objProf!=null){
          objProfile =objProf;
      }
    }
	if(Trigger.isDelete){
		    // If current user is not a System Administrator, do not allow Email Message to be deleted
	         for(EmailMessage objEmailMessage:Trigger.old){
		        if(objProfile !=null && objProfile.Name!='System Administrator'){
		             objEmailMessage.addError('You do not have permission to delete this record, please contact your system administrator.');
		        }
	         }  
	   }
}