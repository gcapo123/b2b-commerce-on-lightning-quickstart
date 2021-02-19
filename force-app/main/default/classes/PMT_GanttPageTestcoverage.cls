/*******************************************************************************************
* Name: PMT_GanttPageTestcoverage
* Description: This test class helps to unit test PMT_GanttPageController_forproject apex methods which helps in formulating gantt chart
* Test class for: PMT_GanttPageController_forproject (87%)
                  PMT_GanttPageController_withfilters (85%) 
*******************************************************************************************/
@isTest
public class PMT_GanttPageTestcoverage {   
    /* Create Test Data */
    @testSetup static void setup(){    
        PMT_Program__c program = new PMT_Program__c();
        program.Name = 'Test Program';
        program.Program_Health__c = 'On Track';
        INSERT program;
        
        PMT_Project__c testProject = new PMT_Project__c();
        testProject.Name = 'New project';
        testProject.Level_of_Effort__c = 'Medium';
        testProject.Program__c = program.Id;
        INSERT testProject;
        
        PMT_Phase__c phase1 = new PMT_Phase__c();
        phase1.Name = 'test phase';
        phase1.Project__c = testProject.Id;
        INSERT phase1;
        
        
        PMT_Task__c task1 = new PMT_Task__c();
        task1.Name = 'Task 01 for project';
        task1.Project_Milestone__c = phase1.Id;
        task1.Assigned_To1__c =UserInfo.getUserId();
        INSERT task1;
        
        PMT_Task__c task2 = new PMT_Task__c();
        task2.Name = 'Subtask for Task 01';
        //task2.Parent_Task__c = task1.Id;
        task2.Project_Milestone__c = phase1.Id;
        task2.Assigned_To1__c =UserInfo.getUserId();
        INSERT task2;
        
        PMT_Task__c task3 = new PMT_Task__c();
        task3.Name = 'Subtask for Task 02';
        //task3.Parent_Task__c = task2.Id;
        task3.Project_Milestone__c = phase1.Id;
        task3.Assigned_To1__c =UserInfo.getUserId();
        INSERT task3;
    }   
    
    
    static testmethod void ganttPageCtrlForProject_TestCase1(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_filter', 'All');    
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        Test.startTest();  
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject(sc);      
        Integer count=ctrl.projectCount;
        system.assertEquals(count, 0, 'As start date not mentioned no project should be added.');       
        Test.stopTest();      
    }
    
    static testmethod void ganttPageCtrlForProject_TestCase2(){
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        List<PMT_Task__c> lstOfTaskRec = [SELECT ID,Start_Date__c,Due_Date__c FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id];
        for(Integer i = 0; i < lstOfTaskRec.size(); i++){
            lstOfTaskRec[i].Start_Date__c = system.today();
            lstOfTaskRec[i].Due_Date__c = system.today() + i + 1;      
        }
        UPDATE lstOfTaskRec;
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_filter', 'All');    
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        Test.startTest();  
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject(sc);      
        Integer count=ctrl.projectCount;      
        system.assertEquals(count, 1, 'As start date mentioned project should be added.');       
        Test.stopTest();      
    }
    
    static testMethod void ganttPageCtrlForProject_TestCase3(){       
        PMT_Project__c projRec = [SELECT ID,Kickoff_formula__c,Deadline_formula__c FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Task__c taskRec = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id AND Name = 'Subtask for Task 02'];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', String.valueOf(taskRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject();
        Test.startTest();  
        ctrl.updateTask();
        PMT_Task__c taskRecOnUpdate=[select id,Start_Date__c,Due_Date__c from PMT_Task__c where id=:taskRec.Id];
        system.assertEquals(10, taskRecOnUpdate.Start_Date__c.daysBetween(taskRecOnUpdate.Due_Date__c)+1, 'There should be 10 days in between start and due date.');
        Test.stopTest();
    }
    
    
    static testMethod void ganttPageCtrlForProject_TestCase4(){      
        
        PMT_Project__c projRec = [SELECT ID,Kickoff_formula__c,Deadline_formula__c FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Task__c taskRec = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id LIMIT 1];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'task_'+String.valueOf(taskRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject();        
        Test.startTest();    
        ctrl.updateTask();
        PMT_Task__c taskRecOnUpdate=[select id,Start_Date__c,Due_Date__c from PMT_Task__c where id=:taskRec.Id];
        system.assertEquals(10, taskRecOnUpdate.Start_Date__c.daysBetween(taskRecOnUpdate.Due_Date__c)+1, 'There should be 10 days in between start and due date.');
        
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlForProject_TestCase5(){
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Phase__c phaseRec = [SELECT ID FROM PMT_Phase__c WHERE Project__c =: projRec.Id];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'phase_'+String.valueOf(phaseRec.Id));
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject();        
        Test.startTest();    
        ctrl.updateTask();      
        system.assertEquals('success', ctrl.saveResult, 'There should not be any error.');
        Test.stopTest();
    }
    
    
    static testMethod void ganttPageCtrlForProject_TestCase6(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'prj_'+String.valueOf(projRec.Id));       
        PMT_GanttPageController_forproject ctrl = new PMT_GanttPageController_forproject();        
        Test.startTest();    
        ctrl.updateTask();
        system.assertEquals('success', ctrl.saveResult, 'There should not be any error.');
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlForProject_TestCase7(){
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Phase__c phaseRec = [SELECT ID FROM PMT_Phase__c WHERE Project__c =: projRec.Id];    
        Test.startTest();
        PMT_GanttPageController_forproject.deletetasks(phaseRec.Id);
        
        List<PMT_Task__c> lstOfTasks = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__c =: phaseRec.Id];
        System.assertEquals(lstOfTasks.isEmpty(), true, 'There should be no task present.');
        Test.stopTest();
    }
    
    static testmethod void  ganttPageCtrlWithfilters_TestCase1(){    
        PMT_Project__c projRec = [SELECT ID, Project_Status__c FROM PMT_Project__c WHERE Name = 'New project'];
        projRec.Project_Status__c = 'Execute';
        UPDATE projRec;
        
        List<PMT_Task__c> lstOfTaskRec = [SELECT ID,Start_Date__c,Due_Date__c FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id];
        for(Integer i = 0; i < lstOfTaskRec.size(); i++){
            lstOfTaskRec[i].Start_Date__c = system.today();
            lstOfTaskRec[i].Due_Date__c = system.today() + i + 1;      
        }
        UPDATE lstOfTaskRec;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(projRec);
        
        PageReference pageRef = new PageReference('/apex/PMT_Ganttpage_withfilters');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_filter', 'All');
        Test.startTest();
        PMT_GanttPageController_withfilters.SearchOption searchOption = new PMT_GanttPageController_withfilters.SearchOption();
        searchOption.searchStatus = true;
        searchOption.scale = 'Month scale';
        searchOption.projectProgress = new List<String>{'Execute'};
            searchOption.taskStatus = 'All';
        searchOption.myProjects = true;
        searchOption.myTasks = false;
        searchOption.followProjects = false;
        searchOption.projectHealth='All';
        searchOption.systemImpacted='All';
        searchOption.projectCategory='All';
        searchOption.fiscalYear='';
        
        String myJSON = JSON.serialize(searchOption);
        ApexPages.currentPage().getParameters().put('searchs', myJSON );
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(stdCtrl);
        ctrl.applysearchfilter();
        System.assertEquals(String.isEmpty(ctrl.datas), false, 'Project data should be generated.');
        Test.stopTest();
    }
    
    static testmethod void ganttPageCtrlWithfilters_TestCase2(){
        PMT_Project__c projRec = [SELECT ID, Project_Status__c,Kickoff_formula__c,Deadline_formula__c FROM PMT_Project__c WHERE Name = 'New project'];
        
        PMT_Task__c taskRec = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id LIMIT 1];
        
        PageReference pageRef = new PageReference('/apex/ganttpage_withfilters');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', String.valueOf(taskRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(stdCtrl);
        
        Test.startTest();
        
        ctrl.updateTask();
        
        PMT_Task__c taskRecOnUpdate=[select id,Start_Date__c,Due_Date__c from PMT_Task__c where id=:taskRec.Id];
        system.assertEquals(10, taskRecOnUpdate.Start_Date__c.daysBetween(taskRecOnUpdate.Due_Date__c)+1, 'There should be 10 days in between start and due date.');
        
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase4(){      
        
        PMT_Project__c projRec = [SELECT ID,Kickoff_formula__c,Deadline_formula__c FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Task__c taskRec = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__r.Project__c =: projRec.Id LIMIT 1];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'task_'+String.valueOf(taskRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);            
        Test.startTest();    
        ctrl.updateTask();
        PMT_Task__c taskRecOnUpdate=[select id,Start_Date__c,Due_Date__c from PMT_Task__c where id=:taskRec.Id];
        system.assertEquals(10, taskRecOnUpdate.Start_Date__c.daysBetween(taskRecOnUpdate.Due_Date__c)+1, 'There should be 10 days in between start and due date.');
        
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase5(){
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Phase__c phaseRec = [SELECT ID FROM PMT_Phase__c WHERE Project__c =: projRec.Id];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'phase_'+String.valueOf(phaseRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);           
        Test.startTest();    
        ctrl.updateTask();      
        system.assertEquals('success', ctrl.saveResult, 'There should not be any error.');
        Test.stopTest();
    }
    
    
    static testMethod void ganttPageCtrlWithfilters_TestCase6(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        
        PageReference pageRef = new PageReference('/apex/PMT_GanttPage_forproject');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_taskId', 'prj_'+String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_startDate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('param_duration', '10');
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);            
        Test.startTest();    
        ctrl.updateTask();
        system.assertEquals('success', ctrl.saveResult, 'There should not be any error.');
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase7(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);
        Test.startTest();
        List<String> ls = ctrl.getProjectProgressValues();
        Test.stopTest();
        System.assertNotEquals(null, ls, 'Project progress picklist values are fetched');        
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase8(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);
        Test.startTest();
        List<SelectOption> ls = ctrl.getPrograms();
        Test.stopTest();
        System.assertNotEquals(null, ls, 'program names found');     
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase9(){
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        PMT_Phase__c phaseRec = [SELECT ID FROM PMT_Phase__c WHERE Project__c =: projRec.Id];    
        Test.startTest();
        PMT_GanttPageController_withfilters.deletetasks(phaseRec.Id);
        
        List<PMT_Task__c> lstOfTasks = [SELECT ID FROM PMT_Task__c WHERE Project_Milestone__c =: phaseRec.Id];
        System.assertEquals(lstOfTasks.isEmpty(), true, 'There should be no task present.');
        Test.stopTest();
    }
    
    static testmethod void ganttPageCtrlWithfilters_TestCase10(){    
        PMT_Project__c projRec = [SELECT ID, Project_Status__c FROM PMT_Project__c WHERE Name = 'New project'];
        projRec.Project_Status__c = 'Plan';
        projRec.Project_Health__c = 'On Track';
        projRec.SystemsImpacted__c = 'Other';
        projRec.Project_Category__c = 'IT';
        UPDATE projRec;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(stdCtrl);
        PageReference pageRef = new PageReference('/apex/PMT_Ganttpage_withfilters');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(projRec.Id));
        ApexPages.currentPage().getParameters().put('param_filter', 'All');
        
        PMT_GanttPageController_withfilters.SearchOption searchOption = new PMT_GanttPageController_withfilters.SearchOption();
        searchOption.searchStatus = true;
        searchOption.scale = 'Month scale';
        searchOption.projectProgress = new List<String>{'Evaluate','Plan','In Progress','Execute'};
            searchOption.taskStatus = 'All';
        searchOption.myProjects = true;
        searchOption.myTasks = false;
        searchOption.followProjects = false;
        searchOption.projectHealth='On Track';
        searchOption.systemImpacted='Other';
        searchOption.projectCategory='IT';
        searchOption.program='Test Program';
        
        String myJSON = JSON.serialize(searchOption);
        ApexPages.currentPage().getParameters().put('searchs', myJSON );        
        Test.startTest();
        ctrl.applysearchfilter();
        System.assertEquals(String.isEmpty(ctrl.datas), false, 'Project data should be generated.');
        Test.stopTest();
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase11(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);
        Test.startTest();
        List<SelectOption> ls = ctrl.getProjectHealth();
        Test.stopTest();
        System.assertNotEquals(null, ls, 'Project Health picklist values are fetched');        
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase12(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);
        Test.startTest();
        List<SelectOption> ls = ctrl.getProjectcategory();
        Test.stopTest();
        System.assertNotEquals(null, ls, 'Project category picklist values are fetched');        
    }
    
    static testMethod void ganttPageCtrlWithfilters_TestCase13(){ 
        PMT_Project__c projRec = [SELECT ID FROM PMT_Project__c WHERE Name = 'New project'];
        ApexPages.StandardController sc = new ApexPages.StandardController(projRec);
        PMT_GanttPageController_withfilters ctrl = new PMT_GanttPageController_withfilters(sc);
        Test.startTest();
        List<String> ls = ctrl.getSystemsImpacted();
        Test.stopTest();
        System.assertNotEquals(null, ls, 'Project Systems Impacted picklist values are fetched');        
    }
}