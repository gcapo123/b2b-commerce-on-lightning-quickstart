public without sharing class ProductInventoryScheduleController {
	@AuraEnabled(cacheable=true)
    public static List<Product_Inventory_Schedule__c> getProductInventorySchedules(String productId) {
        List<Product_Inventory_Schedule__c> theList = [
            SELECT Availability_Window_End__c, Availability_Window_Start__c, Available_For_Preorder__c, Quantity_Available__c 
            FROM Product_Inventory_Schedule__c
            WHERE Product__c = :productId
        	ORDER BY Availability_Window_Start__c ASC];
        return theList;
    }
    
    /**
     * Registers the user to get notifications when the product will be available
     */
   	@AuraEnabled
    public static Product_Inventory_Schedule_Notify__c registerNotify(String productId, String userId) {
        //TODO: check if the user is already registered for the product
        Product_Inventory_Schedule_Notify__c pisn = new Product_Inventory_Schedule_Notify__c();
        
        pisn.Product__c = productId;
        //pisn.OwnerId = userId;
        pisn.Is_Active__c = true;
        List<User> userList = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        if (userList.size() > 0) {
            pisn.Contact__c = userList[0].ContactId;
        }
		
        insert pisn;
        
        return pisn;
    }
    
    /**
     * User contact email 
     */
    @AuraEnabled(cacheable=true)
    public static String getUserEmail(String userId) {
        String contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1][0].ContactId;
        Contact contact = [SELECT Email FROM Contact WHERE Id = :contactId LIMIT 1][0];
        return contact.Email;
    }

}