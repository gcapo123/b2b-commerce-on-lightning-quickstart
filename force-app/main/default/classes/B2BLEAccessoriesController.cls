public with sharing class B2BLEAccessoriesController {

    private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();
    
    @AuraEnabled(cacheable=true)
    public static List<ReturnProduct> getProductSpareParts(String communityId, String productId, String effectiveAccountId) {
        List<Accessory__c> parts = [SELECT Id, Accessory__c FROM Accessory__c WHERE Parent_Product__c = :productId];
        List<ReturnProduct> returnProducts = new List<ReturnProduct>();
        
        //List<ConnectApi.ProductDetail> returnProducts = new List<ConnectApi.ProductDetail>();
        String webstoreId = resolveCommunityIdToWebstoreId(communityId);
        for (integer i=0; i<parts.size(); i++) {
            ReturnProduct rp = new ReturnProduct();
            rp.productId = parts[i].Accessory__c;
            
            ConnectApi.ProductDetail prod = ConnectApi.CommerceCatalog.getProduct(
              webstoreId,
              parts[i].Accessory__c,
              effectiveAccountId,
              null,
              false,
              null,
              false,
              true,
              false
            );
            rp.detailInfo = prod;
            
            ConnectApi.ProductPrice price = ConnectApi.CommerceStorePricing.getProductPrice(
              webstoreId,
              parts[i].Accessory__c,
              effectiveAccountId
            );
            rp.priceInfo = price;
            
            returnProducts.add(rp);
        }
        
        return returnProducts;
    }
    
    /**
     * @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
     * @param  communityId The Id of the community from which the call originated
     * @return weStoreId The webStoreId corresponding to the community Id.
     * @example
     * String webStoreId = B2BUtils.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
    */
    private static String resolveCommunityIdToWebstoreId(String communityId) {
        if (communityIdToWebStoreIdCache.containsKey(communityId)) {
          return communityIdToWebStoreIdCache.get(communityId);
        } else {
          String webStoreId = [
            SELECT WebStoreId
            FROM WebStoreNetwork
            WHERE NetworkId = :communityId
            LIMIT 1
          ]
          .WebStoreId;
          communityIdToWebStoreIdCache.put(communityId, webStoreId);
          return webStoreId;
        }
  	}
    
    @AuraEnabled
  public static ConnectApi.CartItem addToCart(
    String communityId,
    String productId,
    String quantity,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = resolveCommunityIdToWebstoreId(communityId);

    ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
    cartInput.productId = productId;
    cartInput.quantity = quantity;
    cartInput.type = ConnectApi.CartItemType.PRODUCT;

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_CommerceCart_static_methods
    return ConnectApi.CommerceCart.addItemToCart(
      webstoreId,
      effectiveAccountId,
      'active',
      cartInput
    );
  }
    
    public class ReturnProduct {
        @AuraEnabled public String productId {get; set;}
        @AuraEnabled public ConnectApi.ProductDetail detailInfo {get; set;}
        @AuraEnabled public ConnectApi.ProductPrice priceInfo {get; set;}        
    }
}