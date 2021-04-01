public class TestClass {
    public static void test() {
        // If there are several communities, set here your community ID after finding it
        String communityId = '';
        String productListGroupId=[select Id from ElectronicMediaGroup where name='Product List Image'].Id;
        String productDetailGroupId=[select Id from ElectronicMediaGroup where name='Product Detail Images'].Id;

        if (communityId=='') {
            List<Network> networks = [select id, name from Network];
            for (Network network: networks ) {
                System.debug('Community name:'+network.Name+', Community id:'+network.Id);
            }
            if (networks.size() > 1) {
               System.debug('More than one Community. Pick your community Id and rerun');
               return;
            } else {
                communityId = networks[0].Id;            
            }
        }
        ConnectApi.ManagedContentVersionCollection contentCollection = null;
        contentCollection = ConnectApi.ManagedContent.getAllManagedContent(communityId, 0, 200,null, null);
        List<ProductMedia> currentMedia = [select Id,ElectronicMediaGroupId,ElectronicMediaId,ProductId from ProductMedia];
        List<ProductMedia> productMediaToUpsert = new List<ProductMedia>();
        List<Product2> products = [select Id, Name, StockKeepingUnit from Product2];
        for(ConnectApi.ManagedContentVersion mcv : contentCollection.items) {
            Product2 product = findProductBySku(products, mcv.title);
            if (product != null) {
                
                // We can't upsert checking on compound key, so we check here
                if (!mediaExists(currentMedia, productListGroupId, mcv.managedContentId, product.Id) ) {
                    ProductMedia pmList = new ProductMedia();
                    pmList.ElectronicMediaGroupId = productListGroupId;
                    pmList.ElectronicMediaId = mcv.managedContentId;
                    pmList.ProductId = product.Id;
                    productMediaToUpsert.add(pmList);
                }
                if (!mediaExists(currentMedia, productDetailGroupId, mcv.managedContentId, product.Id) ) {
                    ProductMedia pmDetail = new ProductMedia();
                    pmDetail.ElectronicMediaGroupId = productDetailGroupId;
                    pmDetail.ElectronicMediaId = mcv.managedContentId;
                    pmDetail.ProductId = product.Id;
                    productMediaToUpsert.add(pmDetail);
                }
            }
            // Nope:
            // upsert productMediaToUpsert ElectronicMediaGroupId, ElectronicMediaId;
            upsert productMediaToUpsert;            
        }
    }
    static Product2 findProductBySku(List<Product2> productList, String sku) {
        for(Product2 prod: productList) {
            if (prod.StockKeepingUnit == sku) {
                return prod;
            }
        }
        return null;
    }
    static boolean mediaExists(List<ProductMedia> productMediaList, String productGroupId, String mediaId, String productId) {
        for (ProductMedia pm: productMediaList) {
            if (pm.ElectronicMediaGroupId == productGroupId && pm.ElectronicMediaId == mediaId && pm.ProductId == productId) {
                  return true;
            }
        }
        return false;
    }
}
