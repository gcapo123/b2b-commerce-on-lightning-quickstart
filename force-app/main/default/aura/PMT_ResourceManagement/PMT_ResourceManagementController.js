({
    doInit : function(component, event, helper) {
        component.set("v.isLoading",true);
        component.find("PMTDepartment").set("v.value","All");
        component.set("v.capacitySelected","Allocation");
        var date = new Date();
        var currentYear ='FY';
        if(date.getMonth()>0){
            currentYear = currentYear + (parseInt(((date.getYear()+1900).toString()).substring(2,4))+1);
        }
        else{
            currentYear = currentYear + ((date.getYear()+1900).toString()).substring(2,4);
        }
        helper.getResourceAvailabilities(component,helper, currentYear);
    },
    updateManagerId : function(component, event, helper) {
        var managerselected = component.get("v.managerSelected");
        if(managerselected) {
            component.set("v.managerId", managerselected.val);
        } else {
            component.set("v.managerId", null);
        }
    },
    onPeriodFilterChange : function(component, event, helper) {
        var periodSelectedVar = component.get("v.periodSelected");
        helper.getResourceAvailabilities(component,helper, periodSelectedVar);
    },
    handleDeptChange : function(component, event, helper) {
        var deptSelected = event.getSource().get("v.value");
        helper.filterDataByDept(component, helper,deptSelected);
    }
})