({
    GetProducts : function(component, event, helper) {
        var oid = component.get("v.ContactId");
            var action = component.get("c.getccPromotionalProducts");
            action.setCallback(this, function(response) {
                var name = response.getState();
                if (name === "SUCCESS") {
                    component.set("v.ReturnedProduct",response.getReturnValue());
                }else{
                    console.log("Order Error");
                }
            });
            $A.enqueueAction(action);

	},
	onSelect : function(component, event) {
        /* Remove Selected Class from previous element if it exists */
		var PreviousCard = component.get("v.PreviousCard"); 
        if(PreviousCard != ""){
            document.getElementById(PreviousCard).classList.remove("selected");
        }
        /* Selected product adds selected class to element */
        var ProductName = event.currentTarget.getAttribute("data-value");
        var ProductID = event.currentTarget.getAttribute("id");
        var d = document.getElementById(ProductID);
		d.className += " selected";
        component.set("v.selectedCard", ProductName);
        component.set("v.PreviousCard", ProductID);
        component.set("v.ProductId", ProductID);
        $A.util.addClass(ProductID, 'selected');

	}
})