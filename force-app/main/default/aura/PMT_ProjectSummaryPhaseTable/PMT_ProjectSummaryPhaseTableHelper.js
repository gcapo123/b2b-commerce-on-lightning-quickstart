({
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": type + "!",
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    
    getRecords : function(component, event, helper) {
        component.set("v.isLoading",true);
        var action = component.get("c.getSummaryWrapper");
        action.setParams({
            recordId : component.get("v.recordId")
        });
        // Set up the callback
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();            
            
            if(state === "SUCCESS"){
                //if successful stores query results in Lists
                var data = response.getReturnValue();               
                component.set('v.phases', data.phasesList);
                component.set('v.lateTasks', data.lateTaskList);
                component.set('v.tasks', data.onGoingTaskList);
                component.set('v.milestoneTasks', data.milestoneTaskList);
                helper.filterWeek(component, event, helper);
            }else if(state ==='ERROR'){            
                var errors = response.getError();
                var message = '';                                  
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message += errors[0].message;
                }
                helper.showToast("Error", message);
            }else{
                helper.showToast("Error", "Something went wrong, please contact system administrator.");
            } 
            component.set("v.isLoading",false);
        }));
        $A.enqueueAction(action);         
	},
    
    filterWeek : function(component, event, helper){
        var currStart = new Date; // get current date
        var currEnd = new Date;
        var currNextStart = new Date;
        var currNextEnd = new Date;
        var monthDay = currStart.getDate(); //get day of the month
        var weekDay = currStart.getDay(); //get day of the week
        var start = monthDay - weekDay +1; //get first day of the week
        var end = start + 6; //get last day of the week
		var nextStart = end +1; //get first day of next week 
        var nextEnd = nextStart + 6; //get last day of next week
        
        //set dates to ISO format YYYY-MM-DDTimeStamp
        var startDay = new Date(currStart.setDate(start)).toISOString();
        var endDay = new Date(currEnd.setDate(end)).toISOString();
        var nextStartDay = new Date(currNextStart.setDate(nextStart)).toISOString();
        var nextEndDay = new Date(currNextEnd.setDate(nextEnd)).toISOString();
        
        //Assign dates to component attributes in format YYYY-MM-DD
        component.set("v.startCurrent",startDay.substring(0, 10));
        component.set("v.endCurrent",endDay.substring(0, 10));
        component.set("v.startNext",nextStartDay.substring(0, 10));
        component.set("v.endNext",nextEndDay.substring(0, 10));
        
        //Filter columns
        helper.filterTasks(component);
        
    },
    
    filterMonth : function(component, event, helper) {
        var curr = new Date; // get current date
        var month = curr.getMonth(); //get current month
        var year = curr.getFullYear(); //get current year
        var start = 1; //get first day of the month
        var end = new Date(year, month +1, 0).getDate(); //get last day of the month
        var nextStart = end + 1; //get first day of next month
        var nextEnd = new Date(year, month +2, 0).getDate(); //get last day of next month
        
        //set dates to ISO format YYYY-MM-DDTimeStamp
        var startDay = new Date(curr.setDate(start)).toISOString();
        var endDay = new Date(curr.setDate(end)).toISOString();
        var nextStartDay = new Date(curr.setDate(nextStart)).toISOString();
        var nextEndDay = new Date(curr.setDate(nextEnd)).toISOString();
        
        //Assign dates to component attributes in format YYYY-MM-DD
        component.set("v.startCurrent",startDay.substring(0, 10));
        component.set("v.endCurrent",endDay.substring(0, 10));
        component.set("v.startNext",nextStartDay.substring(0, 10));
        component.set("v.endNext",nextEndDay.substring(0, 10));
        
        //Filter columns
		helper.filterTasks(component);
        
	},
    
    filterQuarter : function(component, event, helper) {
        var curr = new Date; // get current date
        var month = curr.getMonth(); //get current month
        var year = curr.getFullYear(); //get current year
        var startQ1 = year+'-02-01';
        var endQ1 = year+'-04-30';
        var startQ1ND = (year+1)+'-02-01';
        var endQ1ND = (year+1)+'-04-30';
        var startQ2 = year+'-05-01';
        var endQ2 = year+'-07-31';
        var startQ3 = year+'-08-01';
        var endQ3 = year+'-10-31';
        var startQ4 = year+'-11-01';
        var endQ4 = (year+1)+'-01-31';
        var startQ4Jan = year-1+'-11-01';
        var endQ4Jan = year+'-01-31';
        
        
        if(month == 1){ //Set quarter if Month of January
            component.set("v.startCurrent", startQ4Jan);
            component.set("v.endCurrent", endQ4Jan);
            component.set("v.startNext", startQ1);
            component.set("v.endNext", endQ1);
            
        }else if((month == 2)||(month == 3)||(month == 4)){ //Set quarter if Month in Q1
            component.set("v.startCurrent", startQ1);
            component.set("v.endCurrent", endQ1);
            component.set("v.startNext", startQ2);
            component.set("v.endNext", endQ2);
            
        }else if((month == 5)||(month == 6)||(month == 7)){ //Set quarter if Month in Q2
            component.set("v.startCurrent", startQ2);
            component.set("v.endCurrent", endQ2);
            component.set("v.startNext", startQ3);
            component.set("v.endNext", endQ3);
            
        }else if((month == 8)||(month == 9)||(month == 10)){ //Set quarter if Month in Q3
            component.set("v.startCurrent", startQ3);
            component.set("v.endCurrent", endQ3);
            component.set("v.startNext", startQ4);
            component.set("v.endNext", endQ4);
            
        }else{ //Set quarter if Month of November or December
            component.set("v.startCurrent", startQ4);
            component.set("v.endCurrent", endQ1);
            component.set("v.startNext", startQ1ND);
            component.set("v.endNext", endQ1ND);
        }
        
        //Filter columns
        helper.filterTasks(component);
	},
    
    filterTasks : function(component){
        //Get relative dates for filter
        var startCurrent = component.get("v.startCurrent");
        var endCurrent = component.get("v.endCurrent");
        var startNext = component.get("v.startNext");
        var endNext = component.get("v.endNext");
        
        //Get current period tasks -> Due Date in current period
        var filteredCurrent = component.get('v.tasks');
        filteredCurrent = filteredCurrent.filter(row=> row.Due_Date__c >= startCurrent && row.Due_Date__c <= endCurrent);
        component.set("v.currentTasks", filteredCurrent);
      	
        //Get next period tasks -> Due date in next period
        var filteredNext = component.get('v.tasks');
        filteredNext = filteredNext.filter(row=> row.Due_Date__c >= startNext && row.Due_Date__c <= endNext);
        component.set("v.nextTasks", filteredNext);

        //Get In Progress Tasks -> Start date in or before current period with Due date after Next period
        var filteredInProgress = component.get('v.tasks');
        filteredInProgress = filteredInProgress.filter(row=> row.Start_Date__c <=endCurrent && row.Due_Date__c > endNext);
        component.set("v.onGoingTasks", filteredInProgress);
    }
})