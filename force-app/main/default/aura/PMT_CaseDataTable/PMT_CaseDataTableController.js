({
	//Component initialization
    doInit : function(component, event, helper) {
        //Get dynamic actions buttons
        var actions = helper.getRowActions.bind(this, component)
        
        //Define columns table
       
        component.set('v.columns', [          
            {label: 'Case Number',fieldName: 'CaseNumber', type: 'button', editable:false, sortable:true, initialWidth:100, typeAttributes: { label: {fieldName: 'CaseNumber'}, variant:'base', class:'slds-truncate',name: 'View', title: 'Click to View Details'}},         
            {label: 'Type', fieldName: 'Type', editable:false, type: 'text', sortable:true,initialWidth: 150,  cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Age',fieldName: 'Days_Open__c', editable:false, type: 'number', sortable:true, initialWidth: 70, cellAttributes:{alignment: 'center', class:{fieldName:'Priority'}}},
            {label: 'Case Title',fieldName: 'Subject', editable:false, type: 'text', sortable:true, cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Description', fieldName: 'Description', editable:false, type: 'text', cellAttributes:{class:{fieldName:'Priority'}}},            
            {label: 'Status', fieldName: 'Status', editable:false, type: 'text', sortable:true,initialWidth: 120,  cellAttributes:{class:{fieldName:'Priority'}}},
            {label: 'Priority', fieldName: 'Priority', editable:false, type: 'text', sortable:true, initialWidth: 100, cellAttributes:{class:{fieldName:'Priority'}}},
            {label: '', type: 'action', cellAttributes:{class:{fieldName:'Priority'}}, typeAttributes: { rowActions: actions } },
        ]);        
        
        helper.getRecords(component, helper); //Get list of allocations	
    },

    //handle row actions
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'View':helper.ViewRecord(component,row.Id);
                break;
            case 'Edit': helper.editRecord(component,row.Id);
                break;
        }
      helper.updateTable(component);
    },
    
    //Handle sorting on datatable columns
    handleSort: function (component, event, helper){
            var fieldName = event.getParam('fieldName');
        	var sortDirection = event.getParam('sortDirection');
        	// assign the latest attribute with the sorted column fieldName and sorted direction
        	 
        	component.set("v.sortedBy", fieldName);
            
        	component.set("v.sortedDirection", sortDirection);
        	helper.sortData(component, fieldName, sortDirection);  
	},
            
    //Handle multiple record selection
    handleRecordsSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedRecords", selectedRows);
        var setRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            setRows.push(selectedRows[i].Id);
        }
        component.set("v.selectedIds", setRows); 
        
    },
    
    //Handle filters for datatable
    handlefilters: function (component, event, helper) {
        helper.updateTable(component);
    }
})