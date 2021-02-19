public class Flow_getProductstoRegister {



    
    @AuraEnabled
    public static String getLastCCOrderAvailable(String cid) {
        List<String> orderItemlist = new List<String>();
        String orders ;

        for(ccrz__E_Order__c ord:[SELECT Id, (select Id, ccrz__Order__c                                               
        		FROM ccrz__E_OrderItems__r  WHERE  ccrz__Product__r.Available_for_Promotion__c  = TRUE ) 
               		FROM ccrz__E_Order__c where ccrz__Contact__c = :cid ]){
                       for(ccrz__E_OrderItem__c oi : ord.ccrz__E_OrderItems__r){
                           orderItemlist.add(oi.ccrz__Order__c);
                       }    
        			}
        orders = [Select Id from ccrz__E_Order__c WHERE Id IN :orderItemlist order by CreatedDate desc LIMIT 1].Id; 
        return orders;
    }
    

    @AuraEnabled
    public static List<ccrz__E_Product__c > getccPromotionalProducts(String cid) {
        List<ccrz__E_Product__c> orderItemlist = [SELECT Id, ccrz__ShortDesc__c, Image_URI__c ,Name FROM ccrz__E_Product__c WHERE Promotional_Item__c = TRUE];
        return orderItemlist;
    }
	@AuraEnabled
    public static List<ccrz__E_Product__c> getccUpsellProducts(String oid) {
        List<String> orderItemlist = new List<String>();
        List<String> ccprodlist = new List<String>();
        
        for(ccrz__E_OrderItem__c ord:[SELECT Id, ccrz__Product__c  FROM ccrz__E_OrderItem__c where ccrz__Order__c  = :oid ]){
        	orderItemlist.add(ord.ccrz__Product__c); 
        }
        
        List<ccrz__E_Product__c > products = [SELECT Id,Available_for_Promotion__c,Name FROM ccrz__E_Product__c WHERE Id IN :orderItemlist];
        return products;
    }
    
        

}