/*****************************************************************************************
* Name: PMT_Utility
* Referenced components: 
- PMT_CaseDataTable.cmp
- PMT_GenLookup.cmp
* Test class : PMT_Testcoverage (96%)
******************************************************************************************/

public with sharing class PMT_Utility {
    /*****************************************************************************************
* Method Name: searchDB
* Description: Generic apex method used to search records depending on dynamic conditions
* Used in :  PMT_GenLookup.cmp
* Return type: JSON of list of ResultWrapper to Lex Components
* Parameters :
@objectName - Name of SObject
@fld_API_Text - API name of field to display to user while searching
@fld_API_Val - API name of field to be returned by Lookup COmponent
@lim   - Total number of record to be returned
@fld_API_Search - API name of field to be searched
@searchText - text to be searched
* *****************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String searchDB(String objectName, String fld_API_Text, String fld_API_Val, 
                                  Integer lim,String fld_API_Search,String searchText ){    
                                      
                                      //Parse search string
                                      searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';
                                      
                                      //Prepare query
                                      String query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
                                          ' FROM '+objectName+
                                          ' WHERE '+fld_API_Search+' LIKE '+searchText+ 
                                          ' LIMIT '+lim;
                                      List<String> fieldsToCheck = new List<String>{fld_API_Text,fld_API_Text,fld_API_Search};
                                      boolean hasAccess = validateCRUD(objectName, fieldsToCheck, 'isAccessible');
                                      if(hasAccess){
                                          //Get the results
                                      	 List<sObject> sobjList = Database.query(query);
                                          List<ResultWrapper> lstRet = new List<ResultWrapper>();
                                          
                                          //Convert to wrapper
                                          for(SObject s : sobjList){
                                              ResultWrapper obj = new ResultWrapper();
                                              obj.objName = objectName;
                                              obj.text = String.valueOf(s.get(fld_API_Text)) ;
                                              obj.val = String.valueOf(s.get(fld_API_Val))  ;
                                              lstRet.add(obj);
                                          }
                                          
                                          return JSON.serialize(lstRet) ;
                                      }
                                      else{
                                          throw new AuraHandledException('You don\'t have access to' + objectName +  '. Please contact system administrator.');
                                      }
                                      
                                  }
    
    /*****************************************************************************************
* Method Name: ResultWrapper - Wrapper class
* Description: Used by searchDB apex method for formating search result in single object     
* *****************************************************************************************/ 
    public class ResultWrapper{
        public String objName {get;set;} //Object Type
        public String text{get;set;} //Text Visible
        public String val{get;set;} //Value Selected
    }
    
    /*****************************************************************************************
* Method Name: getCasesForProject
* Description: Get list of Cases for a project for the Case Datatable on Project Summary page. Used in PMT_CaseDataTable component
* Parameters : Project recordId
* Return Values: list of cases
* *****************************************************************************************/  
    @AuraEnabled
    public static List<Case> getCasesForProject(Id recordId){    
        List<case> cases = new List<case>();
        List<String> lstOfCaseFields = new List<String>{'CaseNumber', 'Subject', 'PMT_Days_Open__c', 'Description', 'Type', 'Status', 'Priority', 'PMT_Project__c'};        
        boolean hasAccess = validateCRUD('Case', lstOfCaseFields, 'isAccessible');
        
        if(hasAccess){  
            cases = [SELECT id,CaseNumber,Subject,PMT_Days_Open__c,Description,Type,Status,Priority,PMT_Project__c FROM Case 
                     WHERE PMT_Project__c =:recordId AND RecordType.DeveloperName =: System.Label.PMT_Project_Record_Type_on_Case ORDER BY Priority ASC, Type ASC limit: limits.getLimitQueryRows()];                                     
            return cases;
            
        }else{
            throw new AuraHandledException('You don\'t have access to related Cases. Please contact system administrator.');
        } 
    }
    
    /*****************************************************************************************
* Method Name: validateCRUD
* Description: Generic method to check CRUD access on object and fields
* Parameters : sObject API name, list of fields, type of access to check
* Return Values: boolean
* *****************************************************************************************/  
    public static boolean validateCRUD(String sObjectName, List<String> lstOfFieldAPIs, String accessCheck){    
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(new String[]{sObjectName});
        
        Map<String, Schema.SObjectField> fieldMap = result[0].fields.getMap();
        
        if(lstOfFieldAPIs == null ){ // Check object level access
            if( (accessCheck.equalsIgnoreCase('isDeletable') && result[0].isDeletable()) ||
               (accessCheck.equalsIgnoreCase('isUpdateable') && result[0].isUpdateable()) ||
               (accessCheck.equalsIgnoreCase('isCreateable') && result[0].isCreateable()) ||
               (accessCheck.equalsIgnoreCase('isAccessible()') && result[0].isAccessible())) {
                   return true;
               }else{
                   return false;
               }
        } else if(lstOfFieldAPIs != null){// Check field level access 
            for (String field : lstOfFieldAPIs) {
                if (accessCheck.equalsIgnoreCase('isAccessible') && !fieldMap.get(field).getDescribe().isAccessible()) {
                    return false;
                }else if (accessCheck.equalsIgnoreCase('isUpdateable') && !fieldMap.get(field).getDescribe().isUpdateable()) {
                    return false;
                }else if (accessCheck.equalsIgnoreCase('isCreateable') && !fieldMap.get(field).getDescribe().isCreateable()) {
                    return false;
                }
            }
            return true;
        }else{
            return false;
        }        
    }
}