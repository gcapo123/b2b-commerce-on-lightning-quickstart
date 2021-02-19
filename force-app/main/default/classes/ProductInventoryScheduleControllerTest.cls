@isTest
public class ProductInventoryScheduleControllerTest {
    
    @isTest static void testGetProductInventorySchedules() {
        String productId = 'testId';
        List<Product_Inventory_Schedule__c> theList = ProductInventoryScheduleController.getProductInventorySchedules(productId);
    }
    
    @isTest static void testRegisterNotify() {
        Product2 product = new Product2();
        product.Name = 'TestProduct';
        insert product;
        
        User u = createPortalUser();
        ProductInventoryScheduleController.registerNotify(product.Id, u.Id);
    }
    
    @isTest static void testGetUserEmail() {
        User u = createPortalUser();
        ProductInventoryScheduleController.getUserEmail(u.id);
    }
    
    private static User createPortalUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus User']; 
        Account a = new Account(Name = 'TestAccount');
        insert a;
        Contact c = new Contact(LastName = 'TestContact', AccountId = a.Id, Email='standarduser@testorg.com');
        insert c;
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com', ContactId = c.id);
        insert u;
        return u;
    }
}