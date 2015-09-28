/**************************************************************************************************
* Project Name..........: RingCentral - BT Support Portal.                                        *
* File..................: SupportPortalArticleCategory.cls                                        *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 19 January 2015                                                         *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....:                                                                         *
* Description...........: This class fetches the list of all the available Data Category,         *
*                         for BT related articles.                                                *
**************************************************************************************************/

global class SupportPortalArticleCategory implements Schedulable {
	
	/* Declaring Variables */  
	public Set<String> DataCategory {get; set;}
	
	/******************************************************************************
    * @Description : Constructor method.                                          *
    * @Params      : void                                                         *
    * @Return      : void                                                         *
    ******************************************************************************/
	public SupportPortalArticleCategory(){	}
	
	/******************************************************************************
    * @Description : Execute class.                                               *
    * @Params      : void                                                         *
    * @Return      : void                                                         *
    ******************************************************************************/
	global void execute(SchedulableContext sc){
		String categoryName; 
		RCNEW_Knowledge_Article__c knowledgeArticleObject; 
		/*Calling methods to fetch Data Category related to BT.*/
		for(String thisRecord : getParentChildCategory()){
			categoryName = thisRecord+','+categoryName; 	
		}
		List<RCNEW_Knowledge_Article__c> knowledgeArticleList = [SELECT Id, Brand__c, BT_Data_Category__c FROM RCNEW_Knowledge_Article__c 
		                                                         WHERE Brand__c =: 'BT Business'];
		
		knowledgeArticleObject = new RCNEW_Knowledge_Article__c();
		knowledgeArticleObject.BT_Data_Category__c = categoryName;
		knowledgeArticleObject.Brand__c = 'BT Business';
		knowledgeArticleObject.Article_List_Order__c = 0; 
		if(knowledgeArticleList != null && knowledgeArticleList.size() > 0){
			knowledgeArticleObject.Id = knowledgeArticleList[0].Id;
		}
		system.debug('#### upserting record = '+knowledgeArticleObject);
		upsert knowledgeArticleObject; 
	}
	
	/*********************************************************************************************
	* @Description : Method to fetch the RC Knowledge Article Version Details.                   *
	* @Params      : void                                                                        * 
	* @Return      : List<Id>                                                                    * 
	*********************************************************************************************/
	public List<Id> getKnowledgeArticleVersionDetails(){
		
		List<Id> knowledgeArticlekvaList = new List<Id>();
	
		for(RC_Knowledge_Article__kav thisRecord : [SELECT  ArticleNumber,ArticleType,Details__c,Id,Key_Words__c,KnowledgeArticleId,
		                                                    Language,PublishStatus,Ranking__c,SourceId,Summary,Title,UrlName,VersionNumber 
													FROM RC_Knowledge_Article__kav 
													WHERE PublishStatus = 'online' AND language = 'en_US' LIMIT 50000]){
			knowledgeArticlekvaList.add(thisRecord.Id);    
	    }	
	    return knowledgeArticlekvaList;
	}

	/*********************************************************************************************
	* @Description : Method to fetch the RC Knowledge Article Data Category.                     *
	* @Params      : List<Id>                                                                    * 
	* @Return      : Set<Id>                                                                     * 
	*********************************************************************************************/
	public Set<String> getKnowledgeArticleDataCategory(List<Id> knowledgeArticlekvaList, String brand){
		
		Set<String> DataCategory = new Set<String>();
		Set<Id> knowledgeArticleParentId = new Set<Id>();
		List<RC_Knowledge_Article__DataCategorySelection> knowledgeArticleDataCategory = [SELECT Id,DataCategoryName, ParentId 
																	  				      FROM RC_Knowledge_Article__DataCategorySelection 
																	 				      WHERE ParentId IN: knowledgeArticlekvaList LIMIT 50000];
		
		for(RC_Knowledge_Article__DataCategorySelection thisRecord : knowledgeArticleDataCategory){
			if(thisRecord.DataCategoryName.equalsIgnoreCase(brand)){
				knowledgeArticleParentId.add(thisRecord.ParentId);	
			}
		}
	
		for(RC_Knowledge_Article__DataCategorySelection thisRecord : knowledgeArticleDataCategory){
			if(knowledgeArticleParentId.contains(thisRecord.ParentId)){
				DataCategory.add(thisRecord.DataCategoryName);	
			}
		}
		return DataCategory;
	}
	
	/*********************************************************************************************
	* @Description : Method to create Data Category Map.                                         *
	* @Params      : Set<String>                                                                 * 
	* @Return      : Map<String, Boolean>                                                        * 
	*********************************************************************************************/
	public Map<String, Boolean> createDataCategoryMap(Set<String> dataCategorySet){
		Map<String, Boolean> dataCategoryMap = new Map<String, Boolean>();
		for(String thisRecord : dataCategorySet){
			dataCategoryMap.put(thisRecord.replace('_',' '), true);	
		}	
		return dataCategoryMap;
	}
	
	/*********************************************************************************************
	* @Description : Method to fetch the Data Category Structure.                                *
	* @Params      :                                                                             * 
	* @Return      : Map<String, Set<String>>                                                    * 
	*********************************************************************************************/
	public Map<String, Set<String>> createDataCategoryStructure(){
		
		List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
		Map<String, Set<String>> dataCategoryParentChildMap = new Map<String, Set<String>>();
		
    	//Creating a list of pair objects to use as a parameter for the describe call
    	List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();         
        DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
        p.setSobject('KnowledgeArticleVersion');
        p.setDataCategoryGroupName('Topic');
        pairs.add(p);
         
     	describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
        if(describeCategoryStructureResult != null && describeCategoryStructureResult.size() > 0){
        	
        	DescribeDataCategoryGroupStructureResult singleResult = describeCategoryStructureResult[0];
         	//Get the top level categories
            DataCategory [] toplevelCategories = singleResult.getTopCategories();
            //Recursively get all the categories
            List<DataCategory> allCategories = getAllCategories(toplevelCategories);
	            

            for(DataCategory category : allCategories) {
               //Get the name of the category
               category.getName();
			   system.debug('#### category.getName() - '+category.getName());
               //Get the label of the category
               category.getLabel();
			   system.debug('#### category.getLabel() - '+category.getLabel());
               //Get the list of sub categories in the category
               DataCategory [] childCategories = category.getChildCategories();
			   if(category.getChildCategories() != null && category.getChildCategories().size() > 0){
					for(DataCategory childCategory : category.getChildCategories()) {
						if(dataCategoryParentChildMap.get(category.getName()) != null){
							dataCategoryParentChildMap.get(category.getName()).add(childCategory.getName());
						}else{
							dataCategoryParentChildMap.put(category.getName(),new Set<String>{childCategory.getName()});
						}
					}
				}
			   system.debug('#### dataCategoryParentChildMap - '+dataCategoryParentChildMap);
            }
         }	
		return dataCategoryParentChildMap;		
	}
	
	/*********************************************************************************************
	* @Description : Method to fetch the Data Category Structure.                                *
	* @Params      :                                                                             * 
	* @Return      : Map<String, Set<String>>                                                    * 
	*********************************************************************************************/
	public Set<String> getParentChildCategory(){
		
		Set<String> DataCategory = new Set<String>();
		Map<String, Boolean> dataCategoryMap = new Map<String, Boolean>();
		
		try{
			DataCategory = getKnowledgeArticleDataCategory(getKnowledgeArticleVersionDetails(), 'BT');
			system.debug('#### Data Category Set = '+DataCategory);
			dataCategoryMap = createDataCategoryMap(DataCategory);
			system.debug('#### Data Category Map = '+dataCategoryMap);
			Map<String, Set<String>> dataCategoryParentChildMap = createDataCategoryStructure();	
			for(String parentCategory : dataCategoryParentChildMap.keySet()){
				if(dataCategoryParentChildMap != null && DataCategory != null && !DataCategory.isEmpty() && 
				  !dataCategoryParentChildMap.get(parentCategory).isEmpty()){
					for(String thisCategory : DataCategory){
						if(dataCategoryParentChildMap.get(parentCategory).contains(thisCategory)){
							DataCategory.add(parentCategory);
						}
					}	
				}	
			}
		}catch(Exception ex){
			system.debug('#### Exception at Line = '+ex.getLineNumber()+' ,Message = '+ex.getMessage());	
		}
		return DataCategory;
	}
	
	/*********************************************************************************************
	* @Description : Method to fetch the Data Category Structure.                                *
	* @Params      : DataCategory []                                                             * 
	* @Return      : DataCategory []                                                             * 
	*********************************************************************************************/
	private static DataCategory[] getAllCategories(DataCategory [] categories){
    	if(categories.isEmpty()){
        	return new DataCategory[]{};
      	} else {
        	DataCategory [] categoriesClone = categories.clone();
         	DataCategory category = categoriesClone[0];
         	DataCategory[] allCategories = new DataCategory[]{category};
         	categoriesClone.remove(0);
         	categoriesClone.addAll(category.getChildCategories());
         	allCategories.addAll(getAllCategories(categoriesClone));
        	return allCategories;
      	}
	}
}// End of Class.