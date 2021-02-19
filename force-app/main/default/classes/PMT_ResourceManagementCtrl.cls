/*************************************************
* Name: PMT_ResourceManagementCtrl
* Description: Lightning component helper for resource allocation
* Author : Shekhar Gawali
* Used By : PMT_ResourceManagement.cmp, 
            PMT_MassResourceAllocationContainer.cmp, 
            PMT_MassResourceAllocation.cmp, 
            PMT_ResourceAvailabilityDataTable.cmp
* Test class : PMT_Testcoverage(93%)
* ***********************************************/
public with sharing class PMT_ResourceManagementCtrl {
    
    Public class ResourceDetail
    {
        @AuraEnabled
        public List<PMT_Resource_Availability__c> ResourceAvailabilities; //All the available resources
        @AuraEnabled
        public List<PMT_Resource_Allocation__c> ResourceAllocations; //Allocations for the project
        @AuraEnabled
        public List<PMT_Resource_Availability__c> dummyAvailabilities; //dummy availabilities for Inov8 user
        @AuraEnabled
        public List<String> roles;  //Roles for picklist
        @AuraEnabled
        public Boolean isCreatable;
    }
    
    /*****************************************************************
     * Method Name : getResourceDetailsWrapper
     * Params : project record
     * Retrun : ResourceDetailWrapper
     * Description : Get data using SOQL and transform to wrapper
     * **************************************************************/
    @AuraEnabled
    public static ResourceDetail getResourceDetailsWrapper(PMT_Project__c project)
    {
        try{                
            //Generate wrapper
            ResourceDetail resource = new ResourceDetail();
            //Private method calls
            List<String> lstOfAllocationFields = new List<String>{'Id','Role__c','Resource_Availability__c', 'Jan__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c','Fiscal_Year__c','Project__c'};
            
            List<String> lstOfAvailabilityFields = new List<String>{'User__c','Feb_Remaining__c','Mar_Remaining__c','Apr_Remaining__c','May_Remaining__c','Jun_Remaining__c','Jul_Remaining__c','Aug_Remaining__c','Sep_Remaining__c','Oct_Remaining__c','Nov_Remaining__c','Dec_Remaining__c', 'Jan_Remaining__c','Id','fiscal_year__c', 'Start_Date__c', 'End_Date__c'};
            
            List<String> lstOfUsersFields = new List<String>{'Name','SmallPhotoURL','ManagerId','IsActive'};
            
            List<String> lstOfProjectFields = new List<String>{'Start_Fiscal_Year__c','End_Fiscal_Year__c','Deadline_formula__c','Kickoff_formula__c'};
            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfAllocationFields, 'isAccessible') && 
                PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isAccessible') && 
                PMT_Utility.validateCRUD('User', lstOfUsersFields, 'isAccessible') && 
                PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjectFields, 'isAccessible')){
                    
                resource.ResourceAllocations = getResourceAllocation(project.Id);
                
                //calculate fiscal years using start and end
                Integer startFiscal = Integer.valueOf(project.Start_Fiscal_Year__c.mid(2,2));
                Integer endFiscal = Integer.valueOf(project.End_Fiscal_Year__c.mid(2,2));
                Integer difference = endFiscal - startFiscal;
                List<String> years = new List<String>();
                for(integer i=0;i<=difference;i++){
                    years.add('FY' + (startFiscal+i));
                }
                
                resource.ResourceAvailabilities = getAvailibility(years, project);
                resource.dummyAvailabilities = getDummyAvailabilities(years, project);
                resource.roles = getRolesPickVals();
                resource.isCreatable = Schema.sObjectType.PMT_Resource_Allocation__c.isCreateable();
                return resource;
            }else{
                throw new AuraHandledException('Access restricted. Please contact system administrator.');          
            }   
        }
        catch(Exception e){
            INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'getResourceDetailsWrapper');
            return null;
        }
    }
    
    /*****************************************************************
     * Method Name : upsertDeleteAllocation
     * Params : List of allocations to save, list of allocations to delete
     * Retrun : n/a
     * Description : upsert/delete the allocation records
     * **************************************************************/
    @AuraEnabled
    public static void upsertDeleteAllocation(List<SObject> allocationsToSave, List<SObject> allocationsToDelete, PMT_Project__c project){
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isCreateable') && PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isUpdateable')){   
            //check if anything to upsert
            if(allocationsToSave!=null){
                List<PMT_Resource_Allocation__c> allocations = new List<PMT_Resource_Allocation__c>();
                allocations.addAll((List<PMT_Resource_Allocation__c>)allocationsToSave);
                try{
                    UPSERT allocations;
                }catch(Exception e){
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'upsertDeleteAllocation');
                }
            }
        }else{
            throw new AuraHandledException('You don\'t have access to update/Insert PMT resource allocation. Please contact system administrator.');            
        }
        
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isDeletable') ){       
            //Check if anything to delete
            if(allocationsToDelete!=null){
                try{
                    DELETE allocationsToDelete;   
                }catch(Exception e){
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'upsertDeleteAllocation');
                }
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete PMT resource allocation. Please contact system administrator.');       
        }       
       
    }
    
    /*****************************************************************
     * Method Name : getRolesPickVals
     * Params : n/a
     * Retrun : List of picklist values
     * Description : Get picklist values of role from resource allocations
     * **************************************************************/
    private static List<String> getRolesPickVals(){
        //call resusable method
        return PMT_TaskandPhaseManagementCtrl.getPicklistvalues('PMT_Resource_Allocation__c', 'Role__c', false);
    }
    
    /*****************************************************************
     * Method Name : getResourceAllocation
     * Params : project record Id
     * Retrun : List of resource allocations
     * Description : Get allocations using SOQL and transform to wrapper
     * **************************************************************/
    private static List<PMT_Resource_Allocation__c> getResourceAllocation(Id projectId)
    {
        List<PMT_Resource_Allocation__c> allocations = new List<PMT_Resource_Allocation__c>();       
        allocations = [select id,Role__c,Resource_Availability__r.User__c,Resource_Availability__r.is_Dummy_Availability__c,
                                                    Resource_Availability__r.User__r.Name,Resource_Availability__r.User_Id__c, Resource_Availability__r.User__r.SmallPhotoURL,
                                                    Resource_Availability__r.User__r.ManagerId,Project__r.Start_Fiscal_Year__c,
                                                    Project__r.End_Fiscal_Year__c,Project__r.Deadline_formula__c,Project__r.Kickoff_formula__c,
                                                    Jan__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,
                                                    Nov__c,Dec__c,Fiscal_Year__c
                                                    from PMT_Resource_Allocation__c where Project__c=:projectId order by Role__c desc limit :limits.getLimitQueryRows()];
        
        return allocations;
    }
    
    
    /*****************************************************************
     * Method Name : getAvailibility
     * Params : project record
     * Retrun : list of reousrce availability
     * Description : Get availabilities using SOQL and transform to wrapper
     * **************************************************************/
    private static List<PMT_Resource_Availability__c> getAvailibility(List<String> years, PMT_Project__c project)
    {
        List<PMT_Resource_Availability__c> ls = new List<PMT_Resource_Availability__c>();
        
        ls = [select User_Id__c,is_Dummy_Availability__c, Feb_Remaining__c,Mar_Remaining__c,Apr_Remaining__c,
                May_Remaining__c,Jun_Remaining__c,Jul_Remaining__c,
                Aug_Remaining__c,Sep_Remaining__c,Oct_Remaining__c,
                Nov_Remaining__c,Dec_Remaining__c, Jan_Remaining__c,
                id,User__c, User__r.name,User__r.SmallPhotoUrl,User__r.ManagerId,
                fiscal_year__c, Start_Date__c, End_Date__c from PMT_Resource_Availability__c
                where fiscal_year__c in :years and User__r.Name!='' and User__r.IsActive = true order by User__r.name limit :limits.getLimitQueryRows()];
        
        return ls;
    }
    
    /*****************************************************************
     * Method Name : getDummyAvailabilities
     * Params : project record
     * Retrun : list of availabilities for Inov8 admin user
     * Description : Get availabilities using SOQL and transform to wrapper
     * **************************************************************/
    private static List<PMT_Resource_Availability__c> getDummyAvailabilities(List<String> years, PMT_Project__c project)
    {
        List<PMT_Resource_Availability__c> dummyAvailablities = new List<PMT_Resource_Availability__c>();
        
        dummyAvailablities = [select Id,User__c,User__r.Name,User__r.SmallPhotoUrl,User__r.Id, 
                              Fiscal_Year__c from PMT_Resource_Availability__c
                              WHERE User__c = null AND Fiscal_Year__c IN: years limit :limits.getLimitQueryRows()];
        
        return dummyAvailablities;
    }
    
    /**********************************************************************************************************************
    @ Method Name:fetchAllResourceAvailabilities
    @ Description :fetch list of resource availability for Resource Management. It is used in PMT_ResourceManagement.cmp
    @ Returns : list of resource availability
    **********************************************************************************************************************/
    @AuraEnabled
    public static ResourcesWrapper fetchAllResourceAvailabilities(String fiscalYear) {
        List<String> lstOfAvailabilityFields = new List<String>{'Id', 'Fiscal_Year__c', 'Apr_Allocation__c', 'Aug_Allocation__c', 'Dec_Allocation__c', 'Feb_Allocation__c', 'Jan_Allocation__c', 'Jul_Allocation__c', 'Jun_Allocation__c', 'Mar_Allocation__c','May_Allocation__c', 'Nov_Allocation__c', 'Oct_Allocation__c', 'Sep_Allocation__c', 'Apr_Remaining__c', 'Aug_Remaining__c', 'Dec_Remaining__c', 'Feb_Remaining__c', 'Jan_Remaining__c', 'Jul_Remaining__c','Jun_Remaining__c', 'Mar_Remaining__c', 'May_Remaining__c', 'Nov_Remaining__c', 'Oct_Remaining__c', 'Sep_Remaining__c', 'Fiscal_Year__c', 'Apr__c', 'Aug__c', 'Dec__c','Feb__c', 'Jan__c', 'Jul__c', 'Jun__c', 'Mar__c', 'May__c', 'Nov__c', 'Oct__c', 'Sep__c', 'Start_Date__c', 'End_Date__c'};
        
        List<String> lstOfUserFields = new List<String>{'Name', 'ManagerId','Department'};
        
        if(PMT_Utility.validateCRUD('PMT_Resource_Availability__c', lstOfAvailabilityFields, 'isAccessible') && PMT_Utility.validateCRUD('User', lstOfUserFields, 'isAccessible')){
            ResourcesWrapper wrapper = new ResourcesWrapper();
            wrapper.Years = new List<String>();
            for(AggregateResult ar : [select count(Id),Fiscal_Year__c fiscalYear from PMT_Resource_Availability__c group by Fiscal_Year__c]){
                wrapper.years.add((String)ar.get('fiscalYear'));
            }
            
            wrapper.resources = [select User_Id__c,is_Dummy_Availability__c, Apr_Allocation__c, Aug_Allocation__c, Dec_Allocation__c, Feb_Allocation__c, 
                                 Jan_Allocation__c, Jul_Allocation__c, Jun_Allocation__c, Mar_Allocation__c, 
                                 May_Allocation__c, Nov_Allocation__c, Oct_Allocation__c, Sep_Allocation__c, Apr_Remaining__c, 
                                 Aug_Remaining__c, Dec_Remaining__c, Feb_Remaining__c, Jan_Remaining__c, Jul_Remaining__c,
                                 Jun_Remaining__c, Mar_Remaining__c, May_Remaining__c, Nov_Remaining__c, Oct_Remaining__c, 
                                 Sep_Remaining__c, Fiscal_Year__c, User__r.Name, User__r.ManagerId, Apr__c, Aug__c, Dec__c, 
                                 Feb__c, Jan__c, Jul__c, Jun__c, Mar__c, May__c, Nov__c, Oct__c, Sep__c, Start_Date__c, 
                                 End_Date__c,User__r.Department from PMT_Resource_Availability__c where  Fiscal_Year__c=:fiscalYear 
                                 and User__r.Name!='' and User__r.isActive=true order by User_Name__c limit :limits.getLimitQueryRows()];
            
            
            return wrapper;
        }else{
            throw new AuraHandledException('Access restricted. Please contact system administrator.');
        }   
    }
    
    /**********************************************************************************************************************
    @ Description :Used in fetchAllResourceAvailabilities apex method for PMT_ResourceManagement.cmp
    **********************************************************************************************************************/
    public class ResourcesWrapper{
        @AuraEnabled
        public List<String> Years;
        @AuraEnabled
        public List<String> Departments;
        @AuraEnabled
        public List<PMT_Resource_Availability__c> resources;
    }
    
     /*************************************************
    * Name: AvailabilityWrapper
    * Description: Wrapper for Avaialbility and whether records are editble. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * ***********************************************/
        public class AvailabilityWrapper{
            @AuraEnabled
            public boolean isResourcePlanner;
            @AuraEnabled
            public List<PMT_Resource_Allocation__c> resourceAvailabilities;
        }
    
    /************************************************
    * Method Name: getAllocationsForResource 
    * Description: Get allocations for resource. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : resourceid, fiscalYear
    * Return Values: list of allocation
    * ***********************************************/    
        @AuraEnabled
        public static AvailabilityWrapper getAllocationsForResource(Id resourceId, String fiscalYear)
        {
            List<String> lstOfAllocationFields = new List<String>{'Id','Name','Role__c','Project_Owner__c','Resource_Availability__c','Project__c','Project_Name__c','Fiscal_Year__c','Resource_Name__c','Feb__c','Mar__c','Apr__c','May__c','Jun__c','Jul__c','Aug__c','Sep__c','Oct__c','Nov__c','Dec__c','Jan__c'};
            
            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfAllocationFields, 'isAccessible')){
                AvailabilityWrapper wrapper = new AvailabilityWrapper();
                wrapper.resourceAvailabilities = [SELECT id,Name,Role__c,Project_Owner__c,Resource_Availability__c,Project__c,Project_Name__c,  Fiscal_Year__c,Resource_Name__c,Feb__c,Mar__c,Apr__c,May__c,Jun__c,Jul__c,Aug__c,Sep__c,Oct__c,Nov__c,Dec__c,Jan__c FROM PMT_Resource_Allocation__c WHERE Resource_Availability__c=:resourceId And Fiscal_Year__c=:fiscalYear order by Project_Name__c ASC, Name ASC limit: limits.getLimitQueryRows()];                                    
                                         
                wrapper.isResourcePlanner = Schema.sObjectType.PMT_Resource_Availability__c.isCreateable();
                return wrapper;
            }else{
                throw new AuraHandledException('You don\'t have access to PMT resource allocations. Please contact system administrator.');
            }   
        }
        
    /*************************************************
    * Method Name: updateAllocations
    * Description: Update allocations. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : allocations
    * Return Values: list of allocations
    * ***********************************************/
        @AuraEnabled
        public static List<PMT_Resource_Allocation__c> updateAllocations(List<PMT_Resource_Allocation__c> allocations){
            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isUpdateable')){   
                try {               
                    UPDATE allocations;
                    return allocations;
                } catch(Exception e) {
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'updateAllocations');
                    return null;
                }
            }else{
                throw new AuraHandledException('You don\'t have access to update PMT resource allocations. Please contact system administrator.');
            }   
        }  
        
    /*************************************************
    * Method Name: deleteRecord
    * Description: delete records. It is used in PMT_ResourceAvailabilityDataTable.cmp
    * Parameters : recordToDelete
    * Return Values: null
    * ***********************************************/
        @auraEnabled
        public static Boolean deleteRecord(sObject recordToDelete) {
            if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', null, 'isDeletable')){    
                try {
                    delete recordToDelete;
                    return true;
                } catch(Exception e) {
                    INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_ResourceManagementCtrl', Error_Message__c = e.getMessage() , Method_Name__c = 'deleteRecord');
                    return false;
                }
            }else{
                throw new AuraHandledException('You don\'t have access to delete PMT resource allocations. Please contact system administrator.');
            }   
        }
    }