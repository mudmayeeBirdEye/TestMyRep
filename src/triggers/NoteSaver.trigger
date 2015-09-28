/*************************************************
Trigger on Note object
After Delete: Prevents non-admin user from deleting Notes.
/************************************************/

trigger NoteSaver on Note (after delete) {
	// Get the current user's profile name
	Profile prof = [select Name from Profile where Id = :UserInfo.getProfileId() ];
	  
	// If current user is not a System Administrator, do not allow Attachments to be deleted
	if (!'System Administrator'.equalsIgnoreCase(prof.Name)) {
		for (Note n : Trigger.old) {
			n.addError('Unable to delete notes.');
		}  
	}
}