({
    getResourceAvailabilities : function(component,helper, periodSelectedVar) {
        //fetch resource availability on page load
        var action = component.get("c.fetchAllResourceAvailabilities");  
        action.setParams({
            'fiscalYear' : periodSelectedVar
        });
        action.setCallback(this,function(response){
            if(response.getState() ==='SUCCESS'){
                var responseVal = response.getReturnValue();
                var departments =[];
                component.set("v.periodValues",responseVal.Years);
                setTimeout(function(){
                    component.find("period").set("v.value",periodSelectedVar);
                    component.set("v.isLoading",false);
                });
                for(var i=0;i<responseVal.resources.length;i++) {
                    //get departments from User
                    if(!departments.includes(responseVal.resources[i].User__r.Department) && responseVal.resources[i].User__r.Department!='' && responseVal.resources[i].User__r.Department!=null)
                        departments.push(responseVal.resources[i].User__r.Department);
                }
                if(departments){
                    component.set("v.departmentList",departments.sort());
                }
                var resAvail = responseVal.resources;
                var fiscalStartMonth = Number($A.get("$Label.c.PMT_FiscalYearStartMonth"));
                const monthNames = ["Jan","Feb", "Mar", "Apr", "May", "Jun",
                            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" 
                           ];
                var fiscalMonths = [];
                //Add months from the current calendar year
                for(var i=fiscalStartMonth-1;i<monthNames.length;i++){
                    fiscalMonths.push(monthNames[i]); 
                }
                //Add remaining fiscal year months from next calendar year
                for(var i=0;i<fiscalStartMonth-1;i++){
                    fiscalMonths.push(monthNames[i]); 
                }
                component.set("v.monthNames",fiscalMonths);
                for(var i=0;i<resAvail.length;i++){
                    var allocations = [];
                    var capacities =[];
                    var availabilities = [];
                    
                    for(var j=0;j<fiscalMonths.length;j++){
                        var fieldName = monthNames[j]+'_Allocation__c';
                        allocations.push(resAvail[i][fieldName]);
                        
                        fieldName = monthNames[j]+'__c';
                        capacities.push(resAvail[i][fieldName]);
                        
                        fieldName = monthNames[j]+'_Remaining__c';
                        availabilities.push(resAvail[i][fieldName]);
                    }
                    resAvail[i].allocations = allocations;
                    resAvail[i].capacities = capacities;
                    resAvail[i].availabilities = availabilities;
                }
                
                
                component.set("v.ResourceAvailability", resAvail);
                component.set("v.ResourceAvailabilityBKP", resAvail);               
                
            }
            else{
                helper.showToast('Error while loading','Something went wrong while loading the component. Please refresh and if error persists contact system administrator.','Error')
            }
        });
        $A.enqueueAction(action);
    },
    showMessage: function(title, message, type) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        resultsToast.fire();
    },
    filterDataOnPeriod : function(component,helper, periodSelectedVar) {
        var allResourceResult = component.get("v.ResourceAvailabilityBKP");
        
        //filter data based on period selected
        if(periodSelectedVar) {
            var arrToFilter = [];
            for(var i=0;i<allResourceResult.length;i++) {
                if(periodSelectedVar == allResourceResult[i].Fiscal_Year__c) {
                    arrToFilter.push(allResourceResult[i]);
                }
                if(arrToFilter) {
                    component.set("v.ResourceAvailability", arrToFilter);
                } else {
                    component.set("v.ResourceAvailability", null);
                }
            }
        }
    },
    filterDataByDept : function(component, helper, deptSelected) {
        var filteredData = component.get("v.ResourceAvailabilityBKP");
        if(deptSelected!='All' & deptSelected!=''){
            filteredData = filteredData.filter(avail => avail.User__r.Department==deptSelected);
        }
        else if(deptSelected!='All' & deptSelected==''){
            filteredData = filteredData.filter(avail => (avail.User__r.Department=='' || avail.User__r.Department==undefined || avail.User__r.Department==null));
        }
        component.set("v.ResourceAvailability", filteredData);
    }
})