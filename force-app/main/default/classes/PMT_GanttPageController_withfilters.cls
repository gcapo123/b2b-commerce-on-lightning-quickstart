/*******************************************************************************************
* Name: PMT_GanttPageController_withfilters
* Description: This class is used for creating gantt chart for all PMT projects using its related data 
* Test class: PMT_GanttPageTestcoverage (85%)
*******************************************************************************************/
public with sharing class PMT_GanttPageController_withfilters {
    /******************************** Variable declaration start************************/
        public String datas { get; set; } 
        public String projectId { get; set; }
        transient public String saveResult { get; set; }
        public Boolean existProject { get; set; }
        transient public String taskStatus { get; set; }
        transient public Map<String, PMT_Resource_Allocation__c> assignmentMap { get; set; }
        public List<String> assignedProjectIds { get; set; }
        transient public Boolean isMyProject { get; set; }
        public String searchs { get; set; }
        transient public SearchOption searchOption { get; set; }
        transient public String loginUserId { get; set; }
        transient public Boolean isLex { get; set; }    
        private Map<String, User> userMap;
        private Set<Id> followIds;
        public Integer userTaskCount { get; set; }
        transient Public Integer daysBetween {get;set;}
        transient public String q1Start { get; set; }
        transient public String q2Start { get; set; }
        transient public String q3Start { get; set; }
        transient public String q4Start { get; set; }
        public static List<PMT_Project__c> lstOfProjects = new List<PMT_Project__c>(); 
    /******************************** Variable declaration end************************/
    
    /*********************************************************************
    * Method Name: DataJson
    * Description : Its wrapper class which is used to generate gantt chart
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/ 
    public class DataJson {
        public String id;               
        public String parent;           
        public String text;             
        public String start_date;       
        public Integer duration;        
        public Boolean open;            
        public List<String> member;     
        public String deadline;         
        public String status;           
        public String project_progress; 
        public String task_status;      
        public String type;          
        public Boolean assigned;        
        public Boolean no_date_task;    
        public String photoUrl;          
        public String helpText;         
        public String signalUrl;        
        public Boolean isFollow;
        public Boolean isCurrentUserTask;    
        public string health_icon;
        public boolean iscomplete;
        public string projectHealth;
        public string projectCategory;
        public String targetQtr;
        public String fiscalYear;
        
        public String program;
        
        public string systemImpacted;        
        public boolean istaskpresent;
        
        public DataJson() {
            this.no_date_task = false;
            this.isFollow = false;
            this.task_status = '';
            this.isCurrentUserTask = false;
        }
    }
    
    /*********************************************************************
    * Method Name: SearchOption
    * Description : Its wrapper class for search feature
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/ 
    public Class SearchOption {
        public Boolean searchStatus;
        public String scale;
        public List<String> projectProgress;
        public String taskStatus;
        public Boolean myProjects;
        public Boolean myTasks;
        public Boolean followProjects;
        public String sDate;
        public String eDate;
        public String projectHealth;
        public String projectCategory;
        public string fiscalYear;      
        
        public String program;        
        public string systemImpacted;
        
        public SearchOption() {
        }
        
        public void setFirstSearchOptions() {
            searchStatus = true;
            scale = 'Month scale';
            
            projectProgress = new List<String>{Label.PMT_DefaultProjectProgressSelected};
                
                program=Label.PMT_DefaultProgramSelected;
            
            taskStatus = 'All';
            myProjects = true;
            myTasks = false;
            followProjects = false;
            projectHealth='All';
            
            systemImpacted='All';
            projectCategory='All';
            
            Integer orgFiscalMonth = Integer.valueOf(System.Label.PMT_FiscalYearStartMonth);
            Date orgFiscalYear = Date.newinstance(system.today().year(), orgFiscalMonth, 1);
            String currentFY = String.Valueof(Integer.valueOf(orgFiscalYear.year()+ 1)); 
            fiscalYear = 'FY'+currentFY.right(2);
            
        }
        
        public SearchOption parse(String s) {
            return (SearchOption)JSON.deserialize(s, SearchOption.class);
        }
    }
    
    /*********************************************************************
    * Method Name: PMT_GanttPageController_withfilters
    * Description : Its standard controller for class
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/ 
    public PMT_GanttPageController_withfilters(ApexPages.StandardController controller) {
        List<String> fields = new List<String>();
        if (!Test.isRunningTest())
        {
            fields.add('Deadline_formula__c');
            fields.add('Kickoff_formula__c');
            controller.addFields(fields);
        }
        
        try{
            PMT_Project__c project = (PMT_Project__c)controller.getRecord();
            System.debug('Kickoff_formula__c='+project.Kickoff_formula__c);
            System.debug('Deadline_formula__c='+project.Deadline_formula__c);
            daysBetween = project.Kickoff_formula__c.daysBetween(project.Deadline_formula__c);
            System.debug('daysBetween='+daysBetween);
        }
        catch(exception e)
        {
            daysBetween = -1;
        }
        initConstructor();
    }
    
    /*********************************************************************
    * Method Name: initConstructor
    * Description : It initializes class variables
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/ 
    @TestVisible private void initConstructor()
    {
        
        loginUserId= UserInfo.getUserId();
        
        assignmentMap = getAssignments();
        system.debug('assignmentMap :'+assignmentMap );
        List<String> lstOfUserFields = new List<String>{'Id', 'Name', 'SmallPhotoUrl', 'UserPreferencesLightningExperiencePreferred'};
        if(PMT_Utility.validateCRUD('User', lstOfUserFields, 'isAccessible')){
            userMap = new Map<String, User>([SELECT Id, Name, SmallPhotoUrl, UserPreferencesLightningExperiencePreferred FROM User where IsActive = true limit :limits.getLimitQueryRows()]);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to User object. Please contact system administartor.'));
            return;
        }   
        
        isLex = userMap.get(loginUserId).UserPreferencesLightningExperiencePreferred;
        
        assignedProjectIds = new List<String>();
        for(PMT_Resource_Allocation__c assign : assignmentMap.values()){
            if(assign.Project__c != null){
                assignedProjectIds.add(assign.Project__c);
            }
        }
        
        projectId = ApexPages.currentPage().getParameters().get('Id');
        List<String> projectIds = new List<String>();
        if(projectId != null){
            projectIds.add(projectId);
        }
        
        integer startMonth = Integer.valueOf(System.Label.PMT_FiscalYearStartMonth);
        Integer currentYear = System.today().year();
        q1Start = String.valueOf(Date.newInstance(currentYear, startMonth, 1)).replace('-', ',');
        q2Start = String.valueOf(Date.newInstance(currentYear,startMonth+3,1)).replace('-', ',');
        q3Start = String.valueOf(Date.newInstance(currentYear,startMonth+6,1)).replace('-', ',');
        q4Start = String.valueOf(Date.newInstance(currentYear,startMonth+9,1)).replace('-', ',');    
        
        getUserSearchOptions();
        
        if (isSearch()) {
            if (isRefineTaskStatus()) {
                ApexPages.currentPage().getParameters().put('param_filter', searchOption.taskStatus);
            }
        }
        system.debug('searchoption:'+searchOption );
        
        List<PMT_Project__c> projects = getProjects();
        lstOfProjects = projects;
        Integer projectNum=0;
        if(projects!=null && projects.size()!=0)
        { 
            system.debug('projects :'+projects);
            if(projects.size() > 1000){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are more than 1000 Projects. Gantt Chart displays only 1000 latest Projects.'));
                List<PMT_Project__c> projects_clone = projects.clone();
                projects.clear();
                for(Integer i = 0; i < 1000; i++){
                    projects.add(projects_clone[i]);
                }
            }
            List<Id> projIds = new List<Id>();
            for(PMT_Project__c proj : projects) {
                projIds.add(proj.Id);
            }
            Map<Id, PMT_Phase__c> milestoneMap = getMileStones(projIds);
            List<Id> phaseIds = new List<Id>();
            if(milestoneMap != null && !milestoneMap.isEmpty()) {
                Set<Id> pIds = milestoneMap.keySet();
                phaseIds.addAll(pIds);
            }
            Map<Id, PMT_Task__c> taskMap = getTasks(phaseIds);
           
            followIds = getFollowIds(projects);
            
            projectNum = setDataToGantt(projects, milestoneMap, taskMap);
        }
        
        existDispPrj(projectNum);
    }
    
    /*********************************************************************
    * Method Name: applysearchfilter
    * Description : It applies specific search filter on results
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/ 
    public void applysearchfilter()
    {
        string searchstring=ApexPages.currentPage().getParameters().get('searchs');
        system.debug('searchstring'+searchstring);
        searchOption = new SearchOption();
        searchOption = searchOption.parse(searchstring);
        
        List<PMT_Project__c> projects = getProjects();
        system.debug('projects :'+projects);
        Integer projectNum=0;
        if(projects!=null && projects.size()!=0)
        { 
            if(projects.size() > 1000){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are more than 1000 Projects. Gantt Chart displays only 1000 latest Projects.'));
                List<PMT_Project__c> projects_clone = projects.clone();
                projects.clear();
                for(Integer i = 0; i < 1000; i++){
                    projects.add(projects_clone[i]);
                }
            }
            List<Id> projectIds = new List<Id>();
            for(PMT_Project__c proj : projects) {
                projectIds.add(proj.Id);
            }
            Map<Id, PMT_Phase__c> milestoneMap = getMileStones(projectIds);
            List<Id> phaseIds = new List<Id>();
            if(milestoneMap != null && !milestoneMap.isEmpty()) {
                Set<Id> pIds = milestoneMap.keySet();
                phaseIds.addAll(pIds);
            }
            Map<Id, PMT_Task__c> taskMap = getTasks(phaseIds);
            
            system.debug('taskMap :'+taskMap );
            
            followIds = getFollowIds(projects);
            
            projectNum = setDataToGantt(projects, milestoneMap, taskMap);
        }
        else
        {
            datas=null;
        }
        existDispPrj(projectNum);
        system.debug('datas:'+datas);
        system.debug('existProject '+existProject );
    }
    
   /*********************************************************************
    * Method Name: setDataToGantt
    * Description : It forms data for gantt chart from project and related data
    * Parameter : Project list, map of Phases and tasks 
    * Returns : Integer
    * *********************************************************************/ 
    public Integer setDataToGantt(List<PMT_Project__c> projects, Map<Id, PMT_Phase__c> phaseMap, Map<Id, PMT_Task__c> taskMap){
        
        system.debug('projects'+projects);
        this.userTaskCount = 0;
        
        Set<String> assignedPrjIds = new Set<String>(this.assignedProjectIds);
        system.debug('assignedPrjIds :'+assignedPrjIds );
        
        List<DataJson> dataJsonList = new List<DataJson>();
        List<DataJson> tempDataJsonList;
        
        Boolean existInvalidData = false;
        
        Integer projectCount = 0;
        
        for(PMT_Project__c project: projects) {
            
            existInvalidData = false;
            tempDataJsonList = new List<DataJson>();
            
            DataJson projectJson = new DataJson();
            projectJson.Id = 'prj_' + String.valueOf(project.Id);
            projectJson.text = project.Name;
            projectJson.start_date = formatDate(project.Kickoff_formula__c, 'dd-MM-yyyy');
            projectJson.duration = Integer.valueOf(project.Duration__c);
            projectJson.member = new List<String>();   
            projectJson.deadline = formatDate(project.Deadline_formula__c, 'dd-MM-yyyy');
            
            projectJson.project_progress = project.Project_Status__c;
            
            projectJson.health_icon=project.Health_Icon__c;
            projectJson.projectHealth=project.Project_Health__c;
            projectJson.projectCategory=project.Project_Category__c;
            
            projectJson.program=project.Program_Text__c;
            
            projectJson.systemImpacted=project.SystemsImpacted__c;
            
            if(userMap.get(project.OwnerId) != null){
                projectJson.photoUrl = userMap.get(project.OwnerId).SmallPhotoUrl;
                projectJson.helpText = userMap.get(project.OwnerId).Name;
            } else {
                projectJson.photoUrl = 'none';
            }
            
            projectJson.signalUrl = '<img style=\"vertical-align:middle; margin:0px 3px;\"src=\"/img/msg_icons/warning24.png\" title=\"There are no tasks in the project\" />';
            
            system.debug('assignedPrjIds.contains(project.Id)'+assignedPrjIds.contains(project.Id));
            if(assignedPrjIds.contains(project.Id)){
                projectJson.assigned = true;
            } else if(UserInfo.getUserId() == project.OwnerId){
                projectJson.assigned = true;
            } else {
                projectJson.assigned = false;
            }
            
            if(project.Kickoff_formula__c == null || project.Deadline_formula__c == null){
                existInvalidData = true;
            }
            if (followIds.contains(project.Id)) {
                projectJson.isFollow = true;
            }
            
            for(PMT_Phase__c milestone: project.Project_Milestones__r) {
                milestone = phaseMap.get(milestone.Id);
                if(milestone != null){
                    
                    DataJson milestoneJson = new DataJson();
                    milestoneJson.Id = 'phase_' + String.valueOf(milestone.Id);
                    milestoneJson.parent = projectJson.Id;
                    milestoneJson.text = milestone.Name;
                    milestoneJson.health_icon=milestone.Health_Icon__c;
                    milestoneJson.start_date = formatDate(milestone.Kickoff_formula__c, 'dd-MM-yyyy');
                    milestoneJson.duration = Integer.valueOf(milestone.Duration__c);
                    milestoneJson.member = new List<String>();  
                    milestoneJson.signalUrl = '';
                    
                    if(milestone.Kickoff_formula__c == null || milestone.Deadline_formula__c == null){
                        existInvalidData = true;
                    }
                    
                    List<PMT_Task__c> tasks = new List<PMT_Task__c>();
                    tasks.addAll(milestone.Project_Tasks__r);
                    if(tasks.size()>0)
                    {
                        milestoneJson.istaskpresent=true;
                    }
                    else
                    {
                        milestoneJson.istaskpresent=false;
                    }
                    
                    
                    for(PMT_Task__c task: tasks) {
                        task = taskMap.get(task.Id);
                        if(task != null)
                        {
                            // Create task data
                            DataJson taskJson = new DataJson();
                            system.debug('task:'+task);
                            
                            system.debug('task :'+task );
                            taskJson.parent = milestoneJson.id;
                            taskJson.text = task.Name;
                            taskJson.Id = 'task_'+String.valueOf(task.Id);
                            taskJson.start_date = formatDate(task.Start_Date__c, 'dd-MM-yyyy');
                            taskJson.duration = Integer.valueOf(task.Duration__c);
                            taskJson.member = new List<String>();
                            taskJson.health_icon=milestoneJson.health_icon;
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
                            taskJson.task_status = task.Status__c;
                            if(task.Start_Date__c == null || task.Due_Date__c== null){
                                existInvalidData = true;
                            }
                            
                            
                            milestoneJson.task_status += ';' + task.Status__c + ';';
                            projectJson.task_status += ';' + task.Status__c + ';';
                            
                            // Whether the logged-in user is Assignee or not
                            if(task.Assigned_To1__c == loginUserId){
                                taskJson.isCurrentUserTask = true;
                                userTaskCount ++;
                                milestoneJson.isCurrentUserTask = true;
                                projectJson.isCurrentUserTask = true;
                            }
                            
                            
                            if((task.Start_Date__c == null || task.Due_Date__c == null) && 
                               (milestone.Kickoff_formula__c != null && milestone.Deadline_formula__c != null)){
                                   taskJson.no_date_task = true;                            
                                   taskJson.start_date = formatDate(milestone.Kickoff_formula__c, 'dd-MM-yyyy');
                                   taskJson.duration = milestone.Kickoff_formula__c.daysBetween(milestone.Deadline_formula__c) + 1;
                               }
                            system.debug('taskJson:'+taskJson);
                            tempDataJsonList.add(taskJson);
                            
                            
                        } else {
                            
                        }
                    }
                    tempDataJsonList.add(milestoneJson);
                } else {
                    
                }
            }
            tempDataJsonList.add(projectJson);
            
            if(!existInvalidData){
                dataJsonList.addAll(tempDataJsonList);
                system.debug('dataJsonList:'+dataJsonList);
                projectCount = ++projectCount;
            }
            else
            {
                system.debug('tempDataJsonList:'+tempDataJsonList); 
            }
        }
        
        this.datas = JSON.serialize(dataJsonList);
        
        return projectCount;
    }
    
    /*********************************************************************
    * Method Name: init
    * Description : It initializes class parameters
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/
    public void init() {
        
        List<PMT_Project__c> projects = getProjects();
        system.debug('projects '+projects );
        if(projects.size() > 1000){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are more than 1000 Projects. Gantt Chart displays only 1000 latest Projects.'));
            List<PMT_Project__c> projects_clone = projects.clone();
            projects.clear();
            for(Integer i = 0; i < 1000; i++){
                projects.add(projects_clone[i]);
            }
        }
        List<Id> projectIds = new List<Id>();
        if(projects != null && projects.size() > 0) {
            for(PMT_Project__c proj : projects) {
                projectIds.add(proj.Id);
            }
        }
        Map<Id, PMT_Phase__c> milestoneMap = getMileStones(projectIds);
        List<Id> phaseIds = new List<Id>();
        if(milestoneMap != null && !milestoneMap.isEmpty()) {
            Set<Id> pIds = milestoneMap.keySet();
            phaseIds.addAll(pIds);
        }
        
        Map<Id, PMT_Task__c> taskMap = getTasks(phaseIds);
        
        Integer projectNum = setDataToGantt(projects, milestoneMap, taskMap);
    }
    
    /*********************************************************************
    * Method Name:updateTask
    * Description : It updates start and due dates on tasks
    * Parameter : NA
    * Returns : NA
    * *********************************************************************/
    public void updateTask(){
        
        SavePoint sp = Database.setSavepoint();
        
        try{
            if(ApexPages.currentPage().getParameters().get('param_taskId').contains('prj_')){
                
                PMT_Project__c updPrj = new PMT_Project__c();
                
                String sDateStr = ApexPages.currentPage().getParameters().get('param_startDate');
                Integer duration = Integer.valueOf(ApexPages.currentPage().getParameters().get('param_duration'));
                Date sDate = Date.valueOf(sDateStr);
                Date eDate = sDate + duration - 1;
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                idStr = idStr.replace('prj_','');
                
                if(PMT_Utility.validateCRUD('PMT_Project__c', null, 'isUpdateable')){
                    updPrj.Id = idStr;                  
                    update updPrj;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Project. Please contact system administartor.'));
                    return;
                }   
                
            } else if(ApexPages.currentPage().getParameters().get('param_taskId').contains('phase_')){
                
                PMT_Phase__c updPhase = new PMT_Phase__c();
                
                String sDateStr = ApexPages.currentPage().getParameters().get('param_startDate');
                Integer duration = Integer.valueOf(ApexPages.currentPage().getParameters().get('param_duration'));
                Date sDate = Date.valueOf(sDateStr);
                Date eDate = sDate + duration - 1;
                
                String idStr = ApexPages.currentPage().getParameters().get('param_taskId');
                idStr = idStr.replace('phase_','');
                System.debug(idStr);
                
                if(PMT_Utility.validateCRUD('PMT_Phase__c', null, 'isUpdateable')){
                    updPhase.Id = idStr;                
                    update updPhase;
                }else{
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to update PMT Project. Please contact system administartor.'));
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
                system.debug('sDateStr '+sDateStr );
                system.debug('duration '+duration );
                system.debug('idStr '+idStr );
                
                if(PMT_Utility.validateCRUD('PMT_Task__c', null, 'isUpdateable')){
                
                    updTask.Id = idStr ;
                    updTask.Start_Date__c = sDate; 
                    updTask.Due_Date__c = eDate;                    
                    update updTask;
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
            
            searchOption = new SearchOption();
            searchOption.setFirstSearchOptions();
            init();
            
        } catch(Exception e) {
            Database.rollback(sp);
            INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_GanttPageController_withfilters', Error_Message__c = e.getMessage() , Method_Name__c = 'UpdateTask');
        }
    }
    
    /*********************************************************************
    * Method Name:getProjects
    * Description : Search for PMT projects with search filters
    * Parameter : NA
    * Returns : List of projects
    * *********************************************************************/
    private List<PMT_Project__c> getProjects() {
        String selectStr = '';
        List<String> lstOfprojectFields = new List<String>{'Id','OwnerId','Name','Kickoff_formula__c','Duration__c', 'Deadline_formula__c','Project_Status__c', 'Project_Health__c','Health_Icon__c','Project_Category__c','Program_Text__c','SystemsImpacted__c'};
        
        List<String> lstOfPhaseFields = new List<String>{'Id', 'Name', 'Kickoff_formula__c', 'Deadline_formula__c'};
        
        if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfprojectFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible')){
         
            selectStr = 'SELECT Id,OwnerId, Name, Kickoff_formula__c, Duration__c, Deadline_formula__c,'
                + '  Project_Status__c, Project_Health__c,Health_Icon__c,Project_Category__c,Program_Text__c,SystemsImpacted__c, '
                + '(SELECT Id FROM Project_Milestones__r ORDER BY Name, Kickoff_formula__c, Deadline_formula__c)'; //@removed Single Project
        
        
            String fromStr = 'FROM PMT_Project__c';
            boolean isWhere=false;
            String whereStr = '';
            
            if(searchOption.projectProgress!=null && searchOption.projectProgress.size()!=0)
            {    isWhere=true;
             whereStr =' WHERE (Project_Status__c=\''+searchOption.projectProgress[0] +'\'';
             System.debug('searchOption.projectProgress='+searchOption.projectProgress);
             for(integer i=1;i<searchOption.projectProgress.size();i++)
             {
                 whereStr =whereStr + ' OR Project_Status__c=\''+searchOption.projectProgress[i] +'\'';
             }
             whereStr=whereStr +')';
             system.debug('whereStr at progress'+whereStr);
            }
            if(searchOption.projectHealth!=null && searchOption.projectHealth!='' && searchOption.projectHealth!='All')
            {
                if(isWhere)
                {
                    whereStr=whereStr+' AND Project_Health__c=\''+searchOption.projectHealth+'\'';
                }
                else
                {
                    isWhere=true;
                    whereStr =' WHERE Project_Health__c=\''+searchOption.projectHealth+'\'';
                }
                system.debug('whereStr at health'+whereStr);
            }
            
            if(searchOption.systemImpacted!=null && searchOption.systemImpacted!='' && !searchOption.systemImpacted.contains('All'))
            {    
                if(isWhere)
                    whereStr=whereStr+' AND SystemsImpacted__c includes (\''+searchOption.systemImpacted+'\')';
                else
                {
                    isWhere=true;
                    whereStr =' WHERE SystemsImpacted__c=\''+searchOption.systemImpacted+'\'';
                }
                system.debug('whereStr at systems impacted'+whereStr);
            }
            if(searchOption.projectCategory!=null && searchOption.projectCategory!='' && searchOption.projectCategory!='All')
            {
                if(isWhere)
                    whereStr=whereStr+' AND Project_Category__c=\''+searchOption.projectCategory+'\'';
                else
                {
                    isWhere=true;
                    whereStr =' WHERE Project_Category__c=\''+searchOption.projectCategory+'\'';  
                }
                system.debug('whereStr at category'+whereStr);
            }
            
            
            if(searchOption.program!=null && searchOption.program!='' && searchOption.program!='All')
            {
                if(isWhere)
                    whereStr=whereStr+' AND Program_Text__c=\''+searchOption.program+'\'';
                else
                {
                    isWhere=true;
                    whereStr =' WHERE Program_Text__c=\''+searchOption.program+'\'';  
                }
            }
            
            String orderByStr = 'ORDER BY Name, Kickoff_formula__c, Deadline_formula__c  ASC';
            String query = selectStr + ' ' + fromStr + ' ' + whereStr + ' ' + orderByStr;
            system.debug('query for getprojects:'+query);
            return Database.query(query);
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project or PMT Phases. Please contact system administartor.'));
            return new List<PMT_Project__c >();
        }
    }
    
    
    /*********************************************************************
    * Method Name:getMileStones
    * Description : Search for PMT phases
    * Parameter : list of project Id's
    * Returns : map of phases related to projects
    * *********************************************************************/
    private Map<Id, PMT_Phase__c> getMileStones(List<Id> projIds) {
        List<String> lstOfPhaseFields = new List<String>{'Id', 'Name','Kickoff_formula__c','Duration__c','Deadline_formula__c','Health_Icon__c', 'Project__c'};
        
        List<String> lstOfTaskFields = new List<String>{'Id','Status__c','Start_Date__c','Due_Date__c','Name'};
        if(PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible')){
            if(projIds != null && projIds.size() > 0) {            
                return new Map<Id, PMT_Phase__c> ([SELECT Id,Name,Kickoff_formula__c,Duration__c,Deadline_formula__c,Health_Icon__c,
                                                    (SELECT Id FROM Project_Tasks__r ORDER BY Start_Date__c,Due_Date__c,Name)
                                                    FROM PMT_Phase__c
                                                    Where Project__c IN: projIds ORDER BY Name ASC limit 50000]);                
                
            }
            return null;
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Phases or tasks. Please contact system administartor.'));
            return new Map<Id, PMT_Phase__c>();
        } 
    }
    
    /****************************************************************************
    * Method Name:getTasks
    * Description : Tasks filtered ids to fix heap size error
    * Parameter : list of phase id's
    * Returns : map of tasks related to phases
    * **************************************************************************/
    private Map<Id, PMT_Task__c> getTasks(List<Id> phaseIds) {
        List<String> lstOfTaskFields = new List<String>{'Name','Start_Date__c','Due_Date__c','Duration__c', 'Percentage_Completion__c','Assigned_To1__c','Status__c','Project_Milestone__c'};
        
        List<String> lstOfPhaseFields = new List<String>{'Project__c'};
        
        if(PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstOfPhaseFields, 'isAccessible')){
            if(phaseIds != null && phaseIds.size() > 0) {
                return new Map<Id, PMT_Task__c>([SELECT Name,Start_Date__c,Due_Date__c,Duration__c,Percentage_Completion__c,Assigned_To1__c,Status__c 
                                                FROM PMT_Task__c
                                                Where Project_Milestone__c IN: phaseIds ORDER BY Start_Date__c,Due_Date__c,Name limit :limits.getLimitQueryRows()]);
                
            }
            return null;
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT task. Please contact system administartor.'));
            return new Map<Id, PMT_Task__c>();
        }   
    }
    
    /**********************************************************************
    * Method Name: getAssignments
    * Description: It search for respurce allocations for current user
    * Parameter : NA
    * Returns : Map
    ************************************************************************/
    private Map<String, PMT_Resource_Allocation__c> getAssignments() {        
        String currentUserId = UserInfo.getUserId();
        List<String> lstOfallocationFields = new List<String>{'Id', 'Project__c', 'Resource_Name__c', 'Allocated_Resource_Id__c'};
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstOfallocationFields, 'isAccessible')){
            return new Map<String, PMT_Resource_Allocation__c>([SELECT Id, Project__c, Resource_Name__c FROM PMT_Resource_Allocation__c WHERE Allocated_Resource_Id__c =: currentUserId limit :limits.getLimitQueryRows()]); 
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT resource allocation object. Please contact system administartor.'));
            return new Map<String, PMT_Resource_Allocation__c>();
        }       
        
    }
    
    /**********************************************************************
    * Method Name: formatDate
    * Description: It formats date to specific format
    * Parameter : Date and Format string
    * Returns : String
    ************************************************************************/
    private String formatDate(Date d, String format) {
        if(d == null) { 
            return null; 
        }
        
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format(format);
    }
    
    /**********************************************************************
    * Method Name: getUser
    * Description: It search for current logged in users gantt search option
    * Parameter : NA
    * Returns : List of users
    ************************************************************************/
    private void existDispPrj(Integer prjNum){
        if(prjNum > 0){
            this.existProject = true;
        } else {
            this.existProject = false;
        }
    }     

    
    /**********************************************************************
    * Method Name: getFollowIds
    * Description: It sets default search options
    * Parameter : List of PMT projects
    * Returns : Set of follow up Id's
    ************************************************************************/
    private Set<Id> getFollowIds(List<PMT_Project__c> projects) {
        Set<Id> proIds = new Set<Id>();
        for (PMT_Project__c p : projects) {
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
    
    /**********************************************************************
    * Method Name: getUserSearchOptions
    * Description: It sets default search options
    * Parameter : NA
    * Returns : NA
    ************************************************************************/
    private void getUserSearchOptions() {
        searchOption = new SearchOption();
        
        searchOption.setFirstSearchOptions();
        
        this.searchs = JSON.serialize(searchOption);
        ApexPages.currentPage().getParameters().put('searchs', this.searchs);
    }
    
    /**********************************************************************
    * Method Name: isSearch
    * Description: checks for searchStatus in searchOption
    * Parameter : NA
    * Returns : Boolean 
    ************************************************************************/
    private Boolean isSearch() {
        return !searchOption.searchStatus ? false : true;
    }
    
    /**********************************************************************
    * Method Name: isRefineTaskStatus
    * Description: Task Status Check whether there is a narrowing down of
    * Parameter : NA
    * Returns : Boolean true：Refine by / False: No refinement
    ************************************************************************/
    private Boolean isRefineTaskStatus() {
        return searchOption.taskStatus == 'All' ? false : true;
    }
    
    /**********************************************************************
    * Method Name: deletetasks
    * Description :fetch program names for picklist on global gantt
    * Parameter : Phase record Id
    * Returns : NA
    ***********************************************************************/
    @RemoteAction
    public static void deletetasks(String phaseid) {
        system.debug('phaseid'+phaseid);
        List<String> lstOfTaskFields = new List<String>{'Id', 'Name','Project_Milestone__c'};
        if(PMT_Utility.validateCRUD('PMT_Task__c', lstOfTaskFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Task__c', null, 'isDeletable')){
            List<PMT_Task__c> task_list=[select id, name,Project_Milestone__c from PMT_Task__c where Project_Milestone__c=:phaseid limit :limits.getLimitQueryRows()];
            system.debug('tasks to be deleted:'+task_list);
            try {
                delete task_list;
            } catch (DmlException e) {
                system.debug('caught exception==='+e);            
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete PMT Task. Please contact system administartor.');            
        }   
    }
    
    /**********************************************************************
    * Method Name:getPrograms
    * Description :fetch program names for picklist on global gantt
    * Parameter : NA
    * Returns : program name options list
    ***********************************************************************/
    public List<SelectOption> getPrograms() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        try {
            List<String> lstOfProgramFields = new List<String>{'Id', 'Program__c', 'Program_Text__c'};
            if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfProgramFields, 'isAccessible')) {
                List<PMT_Project__c> lsPrograms = [select Id, Program__c, Program_Text__c from PMT_Project__c where Program__c != null limit :limits.getLimitQueryRows()];
                Set<String> uniqueProgNames = new Set<String>();
                if(lsPrograms != null && lsPrograms.size() > 0) {
                    for(PMT_Project__c prog : lsPrograms) {
                        if(!uniqueProgNames.contains(prog.Program_Text__c)) {
                            uniqueProgNames.add(prog.Program_Text__c);
                            options.add(new SelectOption(prog.Program_Text__c,prog.Program_Text__c));
                        }
                    }
                }
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project. Please contact system administartor.'));
                return new List<SelectOption>();
            } 
        } catch(Exception e) {
            System.debug('Error occurred in getPrograms: '+e.getMessage());
        }
        return options;
    }
    
    /***************************************************************************
    * Method Name:getProjectProgressValues
    * Description : fetch project status values for picklist on global gantt
    * Parameter : NA
    * Returns : project status list
    * ***************************************************************************/
    public List<String> getProjectProgressValues() {
        List<String> options = new List<String>();
        try{
            List<String> lstOfProjFields= new List<String>{'Project_Status__c'};
            if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjFields, 'isAccessible')) {
                Schema.DescribeFieldResult fieldResult = PMT_Project__c.Project_Status__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry a : ple)
                { 
                    options.add(a.getValue()); 
                }
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project. Please contact system administartor.'));
                return new List<String>();
            } 
        } catch(Exception e) {
            System.debug('Error occurred in getPrograms: '+e.getMessage());
        }
        return options;
    }
    
    /**********************************************************************
    * Method Name:getProjectHealth
    * Description :fetch Project Health for picklist on global gantt
    * Parameter : NA
    * Returns : Project Health options list
    ***********************************************************************/
    public List<SelectOption> getProjectHealth() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        try{
            List<String> lstOfProjFields= new List<String>{'Project_Health__c'};
            if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjFields, 'isAccessible')) {
                Schema.DescribeFieldResult fieldResult = PMT_Project__c.Project_Health__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry a : ple)
                { 
                    options.add(new SelectOption(a.getValue(),a.getValue())); 
                }
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project. Please contact system administartor.'));
                
            } 
        } catch(Exception e) {
            System.debug('Error occurred in getPrograms: '+e.getMessage());
        }
        return options;
    }
    
    /**********************************************************************
    * Method Name:getProjectcategory
    * Description :fetch Project category for picklist on global gantt
    * Parameter : NA
    * Returns : Project category options list
    ***********************************************************************/
    public List<SelectOption> getProjectcategory() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        try{
            List<String> lstOfProjFields= new List<String>{'Project_Category__c'};
            if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjFields, 'isAccessible')) {
                Schema.DescribeFieldResult fieldResult = PMT_Project__c.Project_Category__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry a : ple)
                { 
                    options.add(new SelectOption(a.getValue(),a.getValue())); 
                }
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project. Please contact system administartor.'));
                
            } 
        } catch(Exception e) {
            System.debug('Error occurred in getPrograms: '+e.getMessage());
        }
        return options;       
    }
    
    /**********************************************************************
    * Method Name:getSystemsImpacted
    * Description :fetch SystemsImpacted for picklist on global gantt
    * Parameter : NA
    * Returns : Systems Impacted options list
    ***********************************************************************/
    public List<String> getSystemsImpacted() {
        List<String> options = new List<String>();
        options.add('All');
        try{
            List<String> lstOfProjFields= new List<String>{'SystemsImpacted__c'};
            if(PMT_Utility.validateCRUD('PMT_Project__c', lstOfProjFields, 'isAccessible')) {
                Schema.DescribeFieldResult fieldResult = PMT_Project__c.SystemsImpacted__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry a : ple)
                { 
                    options.add(a.getValue()); 
                }
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You don\'t have access to PMT Project. Please contact system administartor.'));
               
            } 
        } catch(Exception e) {
            System.debug('Error occurred in getPrograms: '+e.getMessage());
        }
        return options;         
      
    }
}