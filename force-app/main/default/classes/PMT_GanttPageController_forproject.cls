/*******************************************************************************************
* Name: PMT_GanttPageController_forproject
* Description: This class is used for creating gantt chart for Project using its related phases and task data
* Test class: PMT_GanttPageTestcoverage (87%)
*******************************************************************************************/
public with sharing class PMT_GanttPageController_forproject {
    /********************************Variable declaration start****************************************/
    transient public String datas { get; set; }
    public String projectId { get; set; }
    transient public String saveResult { get; set; }
    transient public Boolean existProject { get; set; }
    transient public String taskStatus { get; set; }
    public List<String> assignedProjectIds { get; set; }
    transient public Boolean isMyProject { get; set; }
    transient public String searchs { get; set; }
    transient public SearchOption searchOption { get; set; }
    transient public String loginUserId { get; set; }
    transient public Boolean isLex { get; set; }
    private Map<String, String> regionMap;
    private Map<String, User> userMap;
    private Set<Id> followIds;
    public Integer userTaskCount { get; set; }
    transient Public Integer daysBetween {get;set;}
    transient public String q1Start { get; set; }
    transient public String q2Start { get; set; }
    transient public String q3Start { get; set; }
    transient public String q4Start { get; set; }
    Public  Integer projectCount = 0;
  /********************************Variable declaration end****************************************/  
    
  /*****************************************************************
     * Inner class Name : DataJson
     * Description : This wrapper class formulates all data related to project, related phases and task, which is being used for generating gantt chart 
     * **************************************************************/
    public class DataJson implements Comparable{
        public String id;               
        public String parent;           
        public String text;             
        public String start_date;       
        public Integer duration;        
        public Boolean open;            
        public List<String> member;     
        public String deadline;         
        public String status;           
        public String type;             
        public String region;           
        public Boolean assigned;        
        public Boolean no_date_task;    
        public String photoUrl;          
        public String helpText;         
        public String signalUrl;        
        public Boolean isFollow;        
        public Boolean isCurrentUserTask;    
        public string health_icon;
        public boolean iscomplete;
        public boolean istaskpresent;
        
        public DataJson() {
            this.no_date_task = false;
            this.isFollow = false;
            this.isCurrentUserTask = false;
        }
        
        public Integer compareTo(Object compareTo) {
            DataJson compareTodatajson = (DataJson)compareTo;
            if (text == compareTodatajson.text) return 0;
            if (text > compareTodatajson.text) return 1;
            return -1;        
        }
    }
    
  /*****************************************************************
     * Inner class Name : SearchOption
     * Description : This wrapper class used for searching functioanlity
     * **************************************************************/
    public Class SearchOption {
        public Boolean searchStatus;
        public String scale;
        public Boolean myTasks;
        public Boolean followProjects;
        public String sDate;
        public String eDate;
        
        public SearchOption() {
        }
        
        public void setFirstSearchOptions() {
            searchStatus = true;
            scale = 'Month scale';
            myTasks = false;
            followProjects = false;
            
        }        

    }
    
  /*****************************************************************
     * Method name : PMT_GanttPageController_forproject
     * Description : Its standard constructor using PMT Project object
     * **************************************************************/
    public PMT_GanttPageController_forproject (ApexPages.StandardController controller) {
        List<String> fields = new List<String>();
        if (!Test.isRunningTest()){
            fields.add('Deadline_formula__c');
            fields.add('Kickoff_formula__c');
            controller.addFields(fields);
        }
        try{
            PMT_Project__c  project = (PMT_Project__c )controller.getRecord();
            
        }
        catch(exception e)
        {
            daysBetween = -1;
        }
        initConstructor();
    }
    
  /*****************************************************************
     * Method name : PMT_GanttPageController_forproject
     * Description : Its custom constructor without parameter
     * **************************************************************/
    public PMT_GanttPageController_forproject () {        
        initConstructor();
    }
    
  /*******************************************************************
     * Method name : initConstructor
     * Description : It find outs project, phases and related task and generates json for gantt chart
   * Param : NA
   * Return : NA
     * ******************************************************************/
    private void initConstructor() 
    {
        loginUserId= UserInfo.getUserId();
        List<String> lstOfUserFields = new List<String>{'Id', 'Name', 'SmallPhotoUrl', 'UserPreferencesLightningExperiencePreferred'};
        if(PMT_Utility.validateCRUD('User', lstOfUserFields, 'isAccessible')){
            userMap = new Map<String, User>([SELECT Id, Name, SmallPhotoUrl, UserPreferencesLightningExperiencePreferred FROM User limit :limits.getLimitQueryRows()]);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to User object. Please contact system administartor.'));
            return;
        }
        
        isLex = userMap.get(loginUserId).UserPreferencesLightningExperiencePreferred;
        assignedProjectIds = new List<String>();
        projectId = ApexPages.currentPage().getParameters().get('Id');
        
        
        integer startMonth = Integer.valueOf(System.Label.PMT_FiscalYearStartMonth);
        Integer currentYear = System.today().year();
        q1Start = String.valueOf(Date.newInstance(currentYear, startMonth, 1)).replace('-', ',');
        q2Start = String.valueOf(Date.newInstance(currentYear,startMonth+3,1)).replace('-', ',');
        q3Start = String.valueOf(Date.newInstance(currentYear,startMonth+6,1)).replace('-', ',');
        q4Start = String.valueOf(Date.newInstance(currentYear,startMonth+9,1)).replace('-', ',');
        
        getUserSearchOptions();
        List<PMT_Project__c > projects = getProjects(projectId);
        
        List<id> projectids=new list<id>();
        projectids.add(projectId);
        
        Map<Id, PMT_Phase__c> milestoneMap = getMileStones(projectids);
        
        Map<Id, PMT_Task__c> taskMap = getTasks(projectids);
        
        followIds = getFollowIds(projects);
        
        List<DataJson> dataJsonList= setDataToGantt(projects, milestoneMap, taskMap,false);
        
        this.datas = JSON.serialize(dataJsonList);  
        
        existDispPrj(projectCount);
    }
    
    /*******************************************************************
     * Method name : updateTask
     * Description : It find outs task, subtasks related to phases, project. Calculate and updates start and end date on them.
   * Param : NA
   * Return : NA
     * ******************************************************************/
    public void updateTask(){
        
        SavePoint sp = Database.setSavepoint();
        
        try{
            if(ApexPages.currentPage().getParameters().get('param_taskId').contains('prj_')){
                
                PMT_Project__c  updPrj = new PMT_Project__c ();             
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                idStr = idStr.replace('prj_','');
                updPrj.Id = idStr;
                if(PMT_Utility.validateCRUD('PMT_Project__c', null, 'isUpdateable')){
                    UPDATE updPrj;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Project. Please contact system administartor.'));
                    return;
                }
                
            } else if(ApexPages.currentPage().getParameters().get('param_taskId').contains('phase_')){
                
                PMT_Phase__c updPhase = new PMT_Phase__c();            
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                idStr = idStr.replace('phase_','');       
                updPhase.Id = idStr;
                if(PMT_Utility.validateCRUD('PMT_Phase__c', null, 'isUpdateable')){
                    UPDATE updPhase;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Phase. Please contact system administartor.'));
                    return;
                }
                
            } else if(ApexPages.currentPage().getParameters().get('param_taskId').contains('task_')) {
                
                PMT_Task__c updTask = new PMT_Task__c();
                
                String sDateStr = ApexPages.currentPage().getParameters().get('param_startDate');
                Integer duration = Integer.valueOf(ApexPages.currentPage().getParameters().get('param_duration'));
                Date sDate = Date.valueOf(sDateStr);
                Date eDate = sDate + duration - 1;
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                idStr = idStr.replace('task_','');
                
                if(PMT_Utility.validateCRUD('PMT_Task__c', null, 'isUpdateable')){
                    updTask.Id = idStr ;
                    updTask.Start_Date__c = sDate; 
                    updTask.Due_Date__c = eDate; 
                
                    UPDATE updTask;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Task. Please contact system administartor.'));
                    return;
                }
            }else{
                PMT_Task__c updTask = new PMT_Task__c();
                
                String sDateStr = ApexPages.currentPage().getParameters().get('param_startDate');
                Integer duration = Integer.valueOf(ApexPages.currentPage().getParameters().get('param_duration'));
                Date sDate = Date.valueOf(sDateStr);
                Date eDate = sDate + duration - 1;
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                /*idStr = idStr.replace('subtask_','');*/        
                
                System.debug('validateCRUD='+PMT_Utility.validateCRUD('PMT_Task__c', null, 'isUpdateable'));
                if(PMT_Utility.validateCRUD('PMT_Task__c', null, 'isUpdateable')){
                    updTask.Id = idStr ;
                    updTask.Start_Date__c = sDate; 
                    updTask.Due_Date__c = eDate; 
                
                    update updTask;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Task. Please contact system administartor.'));
                    return;
                }   
            }
            saveResult = 'success';
            
            initConstructor();
            
        } catch(Exception e) {
            Database.rollback(sp);
            INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_GanttPageController_forproject', Error_Message__c = e.getMessage() , Method_Name__c = 'updateTask');
        }
    }
  
  /*******************************************************************
     * Method name : setDataToGantt
     * Description : Using project, phases and task data it creates json records as per DataJson wrapper
   * Param : List of project, phases and tasks
   * Return : List of DataJson wrapper records
     * ******************************************************************/
    public List<DataJson> setDataToGantt(List<PMT_Project__c > projects, Map<Id, PMT_Phase__c> phaseMap, Map<Id, PMT_Task__c> taskMap,boolean flag){
        
        this.userTaskCount = 0;
        
        List<DataJson> tempDataJsonList= new List<DataJson>();
        List<DataJson> dataJsonList= new List<DataJson>();
        Boolean existInvalidData = false;
        
        for(PMT_Project__c  project: projects) 
        {
            
            existInvalidData = false;
            tempDataJsonList = new List<DataJson>();
            
            DataJson projectJson = new DataJson();     
            
            projectJson.Id = 'prj_' + String.valueOf(project.Id);
            
            projectJson.text = project.Name;
            projectJson.start_date = formatDate(project.Kickoff_formula__c, 'dd-MM-yyyy');
            projectJson.duration = Integer.valueOf(project.Duration__c);
            projectJson.member = new List<String>();  
            projectJson.deadline = formatDate(project.Deadline_formula__c, 'dd-MM-yyyy');
            
            projectJson.health_icon=project.Health_Icon__c;
            
            if(UserInfo.getUserId() == project.OwnerId){
                projectJson.assigned = true;
            } else {
                projectJson.assigned = false;
            }
            
            if( project.Kickoff_formula__c == null || project.Deadline_formula__c == null ){
                existInvalidData = true;
            }
            
            if (followIds.contains(project.Id)) {
                projectJson.isFollow = true;
            }
            
            for(PMT_Phase__c milestone: project.Project_Milestones__r) {      
                milestone = phaseMap.get(milestone.Id);
                if(milestone != null){
                    
                    DataJson phaseJson = new DataJson();
                    phaseJson.Id = 'phase_' + String.valueOf(milestone.Id);
                    phaseJson.parent = projectJson.Id;
                    phaseJson.text = milestone.Name;
                    phaseJson.health_icon=milestone.Health_Icon__c;
                    phaseJson.start_date = formatDate(milestone.Kickoff_formula__c, 'dd-MM-yyyy');
                    phaseJson.duration = Integer.valueOf(milestone.Duration__c);
                    phaseJson.member = new List<String>();  
                    phaseJson.signalUrl = '';
                    
                    if(milestone.Kickoff_formula__c == null || milestone.Deadline_formula__c == null){
                        existInvalidData = true;
                    }
                    
                    List<PMT_Task__c> tasks = new List<PMT_Task__c>();
                    tasks.addAll(milestone.Project_Tasks__r);
                    if(tasks.size()>0)
                    {
                        phaseJson.istaskpresent=true;
                    }
                    else
                    {
                        phaseJson.istaskpresent=false;
                    }
                    
                    for(PMT_Task__c task: tasks) {
                        task = taskMap.get(task.Id);
                        if(task != null)
                        {  
                            DataJson taskJson = new DataJson();                           
                                taskJson.parent = phaseJson.id;
                                taskJson.text = task.Name;
                                taskJson.Id = 'task_'+String.valueOf(task.Id);
                                taskJson.start_date = formatDate(task.Start_Date__c, 'dd-MM-yyyy');
                                taskJson.duration = Integer.valueOf(task.Duration__c);
                                taskJson.member = new List<String>();
                                taskJson.health_icon=phaseJson.health_icon;
                                if(task.Status__c=='Completed'||task.Status__c=='Closed, not Completed')
                                {
                                    taskJson.iscomplete=true;
                                }
                                else
                                {
                                    taskJson.iscomplete=false;
                                }
                                
                                if(task.Assigned_To1__c != null && userMap.get(task.Assigned_To1__c) != null){
                                    taskJson.photoUrl = userMap.get(task.Assigned_To1__c).SmallPhotoUrl;
                                    taskJson.helpText = userMap.get(task.Assigned_To1__c).Name;
                                }
                                taskJson.signalUrl = '';
                                if(task.Start_Date__c == null || task.Due_Date__c== null){
                                    existInvalidData = true;
                                }
                                // Whether the logged-in user is Assignee or not
                                if(task.Assigned_To1__c == loginUserId){
                                    taskJson.isCurrentUserTask = true;
                                    userTaskCount ++;
                                    phaseJson.isCurrentUserTask = true;
                                    projectJson.isCurrentUserTask = true;
                                }
                                
                                /*When the display conditions (values ​​in StartDate and EndDate are not satisfied), turn on the non-display flag. -> ×
↓ Specification change as below
In the case of "task" which does not satisfy the display condition,
Set the date unset task flag to True,
Set the Start / End value of Phase.*/
                                
                                if((task.Start_Date__c == null || task.Due_Date__c == null) && 
                                   (milestone.Kickoff_formula__c != null && milestone.Deadline_formula__c != null)){
                                       taskJson.no_date_task = true;                            
                                       taskJson.start_date = formatDate(milestone.Kickoff_formula__c, 'dd-MM-yyyy');
                                       taskJson.duration = milestone.Kickoff_formula__c.daysBetween(milestone.Deadline_formula__c) + 1;
                                   }
                                tempDataJsonList.add(taskJson);
                            //}             
                        } 
                    }
                    tempDataJsonList.add(phaseJson);
                } 
                
            }
            tempDataJsonList.add(projectJson);
            System.debug('tempDataJsonList='+tempDataJsonList.size());
            System.debug('existInvalidData='+existInvalidData);
            
            if(!existInvalidData){
                dataJsonList.addAll(tempDataJsonList);        
                projectCount = ++projectCount;
            } 
            System.debug('projectCount='+projectCount);         
        }
        
        
        return dataJsonList;
    }
    
  /*******************************************************************
     * Method name : getProjects
     * Description : It queries and return PMT project record as per Id provided
   * Param : Id of project
   * Return : List of PMT projects
     * ******************************************************************/
    private List<PMT_Project__c > getProjects(String pIds) {
        List<String> lstOfprojectFields = new List<String>{'Id','OwnerId','Name','Kickoff_formula__c','Duration__c', 'Deadline_formula__c','Project_Status__c', 'Project_Health__c','Health_Icon__c'};
        
        List<String> lstOfPhaseFields = new List<String>{'Id', 'Name', 'Kickoff_formula__c', 'Deadline_formula__c'};
        
        if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfprojectFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible')){

            String selectStr = 'SELECT Id,OwnerId,Name, Kickoff_formula__c,Duration__c, Deadline_formula__c,'
                + '  Project_Status__c, Project_Health__c,Health_Icon__c, '
                + '(SELECT Id FROM Project_Milestones__r ORDER BY Name, Kickoff_formula__c, Deadline_formula__c)';
            String fromStr = 'FROM PMT_Project__c ';
            String whereStr = '';
            whereStr = ' WHERE Id =:pIds ';
        
            String orderByStr = 'ORDER BY Name, Kickoff_formula__c, Deadline_formula__c  ASC';
            String query = selectStr + ' ' + fromStr + ' ' + whereStr + ' ' + orderByStr;
        
            return Database.query(query);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project or PMT Phases. Please contact system administartor.'));
            return new List<PMT_Project__c >();
        }
    }
    
  /*******************************************************************
     * Method name : getMileStones
     * Description : It queries and return PMT Phases and PMT task records related to project
   * Param : Id of project
   * Return : List of PMT Phases
     * ******************************************************************/
    private Map<Id, PMT_Phase__c> getMileStones(List<id> projectid) {
        List<String> lstOfPhaseFields = new List<String>{'Id', 'Name','Kickoff_formula__c','Duration__c','Deadline_formula__c','Health_Icon__c', 'Project__c'};
        
        List<String> lstOfTaskFields = new List<String>{'Id','Status__c','Start_Date__c','Due_Date__c','Name'};
        
        if(PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible')){
        
            return new Map<Id, PMT_Phase__c> ([ SELECT Id, Name,Kickoff_formula__c,Duration__c,Deadline_formula__c,Health_Icon__c,
                                            (SELECT Id,Status__c FROM Project_Tasks__r ORDER BY Start_Date__c,Due_Date__c,Name)
                                            FROM PMT_Phase__c
                                            WHERE Project__c in :projectid ORDER BY Name ASC limit :limits.getLimitQueryRows()]);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Phases or tasks. Please contact system administartor.'));
            return new Map<Id, PMT_Phase__c>();
        }                                   
       
    }
    
  /*******************************************************************
     * Method name : getTasks
     * Description : It queries and return PMT task records related to project
   * Param : Id of project
   * Return : List of PMT Tasks
     * ******************************************************************/    
    private Map<Id, PMT_Task__c> getTasks(List<id> projectid) {
        List<String> lstOfTaskFields = new List<String>{'Name','Start_Date__c','Due_Date__c','Duration__c', 'Percentage_Completion__c','Assigned_To1__c','Status__c','Project_Milestone__c'};
        
        List<String> lstOfPhaseFields = new List<String>{'Project__c'};
        
        if(PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible')){
            return new Map<Id, PMT_Task__c>([SELECT Name,Start_Date__c,Due_Date__c,Duration__c, Percentage_Completion__c,Assigned_To1__c,Status__c 
                                        FROM PMT_Task__c
                                        WHERE Project_Milestone__r.Project__c in :projectid ORDER BY Start_Date__c,Due_Date__c,Name limit :limits.getLimitQueryRows() ]);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT task. Please contact system administartor.'));
            return new Map<Id, PMT_Task__c>();
        }                                   
            
       
    }
    
  /*******************************************************************
     * Method name : formatDate
     * Description : It format the date as per requirement and retrun it
   * Param : Date and format into which it need to convert
   * Return : String
     * ******************************************************************/   
    private String formatDate(Date d, String format) {
        if(d == null) { return null; }
        
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format(format);
    }
    
    
  /*******************************************************************
     * Method name : existDispPrj
     * Description : It sets existProject variable as per count
   * Param : Integer
   * Return : NA
     * ******************************************************************/ 
    private void existDispPrj(Integer prjNum){
        if(prjNum > 0){
            this.existProject = true;
        } else {
            this.existProject = false;
        }
    }    

    
    /*******************************************************************
     * Method name : getFollowIds
     * Description : It search for projects to which current user is subscribed/following
   * Param : List of projects
   * Return : Set of project Id's
     * ******************************************************************/ 
    private Set<Id> getFollowIds(List<PMT_Project__c > projects) {
        Set<Id> proIds = new Set<Id>();
        for (PMT_Project__c  p : projects) {
            proIds.add(p.Id);
        }
        
        Set<Id> followProjectId = new Set<Id>();
        List<String> lstOfEntitySubscrFields = new List<String>{'Id', 'ParentId', 'SubscriberId'};
        if(PMT_Utility.validateCRUD('EntitySubscription', lstOfEntitySubscrFields, 'isAccessible')){
            List<EntitySubscription> eList = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN: proIds AND SubscriberId =: UserInfo.getUserId() LIMIT 1000];
            for (EntitySubscription e : eList) {
                followProjectId.add(e.ParentId);
            }
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Access restricted, please contact system administrator.'));
            return new Set<Id>();
        }   
        return followProjectId;
    }
    
    /*******************************************************************
     * Method name : getUserSearchOptions
     * Description : It search for users search option and set it as page parameter
   * Param : NA
   * Return : NA
     * ******************************************************************/ 
    private void getUserSearchOptions() {        
        searchOption = new SearchOption();
        searchOption.setFirstSearchOptions();
        this.searchs = JSON.serialize(searchOption);
        ApexPages.currentPage().getParameters().put('searchs', this.searchs);
    }
 
    
    /*******************************************************************
     * Method name : deletetasks
     * Description : It deletes tasks related to phase
   * Param : PMT phase Id
   * Return : NA
     * ******************************************************************/ 
    @RemoteAction
    public static void deletetasks(String phaseid) {    
        List<String> lstOfTaskFields = new List<String>{'Id', 'Name','Project_Milestone__c'};
        if(PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Task__c', null, 'isDeletable')){
            List<PMT_Task__c> task_list=[select id, name,Project_Milestone__c from PMT_Task__c where Project_Milestone__c=:phaseid limit :limits.getLimitQueryRows()];    
            try {
                delete task_list;
            } catch (DmlException e) {
                
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete PMT Task. Please contact system administartor.');
            
        }
    }
    
}