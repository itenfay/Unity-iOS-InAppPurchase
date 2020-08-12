//
//  UnityIAPConnector.mm
//
//  Created by dyf on 2020/4/16. ( https://github.com/dgynfi/Unity-iOS-InAppPurchase )
//  Copyright © 2020 dyf. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "UnityIAPConnector.h"
#import "DYFStoreManager.h"

/// This is used to store the name of the `GameObject` object.
static NSString *s_callbackGameObject;
/// This is used to store a function name of the `GameObject` object.
static NSString *s_callbackFunc;


/// This function (UnitySendMessage) is declared in UnityInterface.h.
#if !defined(__UN_SEND_MSG)
#define __UN_SEND_MSG(s_msg) UnitySendMessage([s_callbackGameObject UTF8String], [s_callbackFunc UTF8String], [s_msg UTF8String])
#endif

/// A string created by copying the data from bytes.
#if !defined(__OBJC_STRING)
#define __OBJC_STRING(c_str) ({ NSString *s = nil; if (c_str) { s = [NSString stringWithUTF8String:c_str]; } s; })
#endif

/// The empty string for Objective-C.
NSString *const OCEmptyString = @"";

/// This function is used to callback message data to unity.
void UNCallbackMessageDataToUnity(int msgCode, id msgData) {
    
    MKVContainer *dataBody = [MKVContainer container];
    [dataBody setValue:@(msgCode) forKey:@"msg_code"];
    [dataBody setValue:msgData forKey:@"msg_data"];
    
    NSString *msg = [UnityIAPConnector jsonWithObject:dataBody];
    msg ? __UN_SEND_MSG(msg) : __UN_SEND_MSG(OCEmptyString);
}

/// Returns the localized price of a given product.
static NSString *UNLocalizedPrice(SKProduct *product) {
    return [DYFStore.defaultStore localizedPriceOfProduct:product];
}


#if defined(_cplusplus)
extern "C"{
#endif

    /// Initializes message callback for Unity.
    /// @param callbackGameObject The gameObject name comes from Unity.
    /// @param callbackFunc The function name comes from Unity.
    void DYFInitUnityMsgCallback(const char* callbackGameObject, const char* callbackFunc)
    {
        NSCAssert(callbackGameObject != NULL, @"The callback gameobject is null");
        NSCAssert(callbackFunc != NULL, @"The callback function is null");
        s_callbackGameObject = __OBJC_STRING(callbackGameObject);
        s_callbackFunc = __OBJC_STRING(callbackFunc);
#if DEBUG
        NSLog(@"%s s_callbackGameObject: %@, s_callbackFunc: %@", __func__, s_callbackGameObject, s_callbackFunc);
#endif
    }
    
    /// Step 1: Requests localized information about a product from the Apple App Store.
    /// Step 2: Adds payment of the product with the given product identifier.
    void DYFRetrieveProductFromAppStore(const char* productId)
    {
        if (![DYFStore canMakePayments]) {
            
            MKVContainer *item = [MKVContainer container];
            [item setValue:@"This device is not able or allowed to make payments!" forKey:@"err_desc"];
            UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_CANNOT_MAKE_PAYMENTS, item);
            
            return;
        }
        
        NSString *productIdentifier = __OBJC_STRING(productId);
        
        [DYFStore.defaultStore requestProductWithIdentifier:productIdentifier success:^(NSArray *products, NSArray *invalidIdentifiers) {
            
            if (products.count == 1) {
                
                NSString *productId = ((SKProduct *)products[0]).productIdentifier;
                MKVContainer *item = [MKVContainer container];
                [item setValue:productId forKey:@"p_id"];
                
                UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_GET_PRODUCT_SUCCESSFULLY, item);
                
            } else {
                
                // There is no this product for sale!
                MKVContainer *item = [MKVContainer container];
                [item setValue:@"There is no this product for sale!" forKey:@"err_desc"];
                UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_NO_PRODUCT_FOR_SALE, item);
            }
            
        } failure:^(NSError *error) {
            
            NSString *value = error.userInfo[NSLocalizedDescriptionKey];
            NSString *msg = value ?: error.localizedDescription;
            
            MKVContainer *item = [MKVContainer container];
            [item setValue:@(error.code) forKey:@"err_code"];
            [item setValue:msg forKey:@"err_desc"];
            
            UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_FAIL_TO_GET_PRODUCT, item);
        }];
    }

    /// Step 1: Requests localized information about a set of products from the Apple App Store.
    /// Step 2: After retrieving the localized product list, then display store UI.
    /// Step 3: Adds payment of the product with the given product identifier.
    void DYFRetrieveProductsFromAppStore(const char* productIds)
    {
        if (![DYFStore canMakePayments]) {
            
            MKVContainer *item = [MKVContainer container];
            [item setValue:@"This device is not able or allowed to make payments!" forKey:@"err_desc"];
            UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_CANNOT_MAKE_PAYMENTS, item);
            
            return;
        }
        
        NSString *jsonForProductIds = __OBJC_STRING(productIds);
        NSArray *productIdentifiers = [UnityIAPConnector objectWithJson:jsonForProductIds];
        
        [DYFStore.defaultStore requestProductWithIdentifiers:productIdentifiers success:^(NSArray *products, NSArray *invalidIdentifiers) {
            
            if (products.count > 0) {
                
                NSMutableArray *itemArr = [NSMutableArray array];
                
                for (SKProduct *p in products) {
                    
                    MKVContainer *item = [MKVContainer container];
                    [item setValue:p.productIdentifier forKey:@"p_id"];
                    [item setValue:p.localizedTitle forKey:@"p_title"];
                    [item setValue:p.price.stringValue forKey:@"p_price"];
                    [item setValue:UNLocalizedPrice(p) forKey:@"p_localized_price"];
                    [item setValue:p.localizedDescription forKey:@"p_localized_desc"];
                    
                    [itemArr addObject:item];
                }
                
                UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_GET_PRODUCTS_SUCCESSFULLY, itemArr);
                
            } else if (products.count == 0 && invalidIdentifiers.count > 0) {
                
                // Please check the product information you set up.
                MKVContainer *item = [MKVContainer container];
                [item setValue:@"There are no products for sale!" forKey:@"err_desc"];
                [item setValue:invalidIdentifiers forKey:@"invalid_ids"];
                UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_NO_PRODUCTS_FOR_SALE, item);
            }
            
        } failure:^(NSError *error) {
            
            NSString *value = error.userInfo[NSLocalizedDescriptionKey];
            NSString *msg = value ?: error.localizedDescription;
            
            MKVContainer *item = [MKVContainer container];
            [item setValue:@(error.code) forKey:@"err_code"];
            [item setValue:msg forKey:@"err_desc"];
            
            UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_FAIL_TO_GET_PRODUCTS, item);
        }];
    }
    
    /// Adds payment of the product with the given product identifier, an opaque identifier for the user’s account.
    void DYFAddPayment(const char* productId, const char* userId)
    {
        NSString *productIdentifier = __OBJC_STRING(productId);
        NSString *userIdentifier = __OBJC_STRING(userId);
        [DYFStoreManager.shared addPayment:productIdentifier userIdentifier:userIdentifier];
    }

    /// Restores previously completed purchases with an opaque identifier for the user’s account.
    void DYFRestoreTransactions(const char* userId)
    {
        NSString *userIdentifier = __OBJC_STRING(userId);
        [DYFStoreManager.shared restoreTransactions:userIdentifier];
    }
    
    /// Refreshes the App Store receipt in case the receipt is invalid or missing.
    void DYFRefreshReceipt()
    {
        [DYFStoreManager.shared refreshReceipt];
    }

    /// Completes a pending transaction.
    void DYFFinishTransaction(const char* transactionId)
    {
        NSString *transactionIdentifier = __OBJC_STRING(transactionId);
        
        DYFStore *store = DYFStore.defaultStore;
        SKPaymentTransaction *pt = [store extractPurchasedTransaction:transactionIdentifier];
        
        if (pt) {
            
            [DYFStore.defaultStore finishTransaction:pt];
            
        } else {
            
            SKPaymentTransaction *rt = [store extractRestoredTransaction:transactionIdentifier];
            [DYFStore.defaultStore finishTransaction:rt];
        }
        
        DYFStoreKeychainPersistence *persister = store.keychainPersister;
        [persister removeTransaction:transactionIdentifier];
    }

    /// Queries those incompleted transactions from keychain.
    void DYFQueryIncompletedTransactions()
    {
        [DYFStoreManager.shared queryIncompletedTransactions];
    }

#if defined(_cplusplus)
}
#endif


@implementation UnityIAPConnector

+ (NSString *)jsonWithObject:(id)object {
    
    if ([NSJSONSerialization isValidJSONObject:object]) {
        
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:object options:kNilOptions error:&error];
        if (!error) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
#if DEBUG
        NSLog(@"%s: %@", __FUNCTION__, error.description);
#endif
    }
    
    return nil;
}

+ (id)objectWithJson:(NSString *)json {
    
    if (json && json.length > 0) {
        
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        id obj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!error) {
            return obj;
        }
        
#if DEBUG
        NSLog(@"%s: %@", __FUNCTION__, error.description);
#endif
    }
    
    return nil;
}

@end


/// Note: This function is declared in UnityInterface.h.
//void UnitySendMessage(const char* obj, const char* method, const char* msg) {}


@implementation NSMutableDictionary (UNTypeDef)

+ (instancetype)container {
    return [NSMutableDictionary dictionary];
}

@end
