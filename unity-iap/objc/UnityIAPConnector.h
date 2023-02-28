//
//  UnityIAPConnector
//
//  Created by chenxing on 2020/4/16. ( https://github.com/chenxing640/Unity-iOS-InAppPurchase )
//  Copyright © 2020 chenxing. All rights reserved.
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

#import <Foundation/Foundation.h>

/// Note: This function is declared in UnityInterface.h.
//extern void UnitySendMessage(const char* obj, const char* method, const char* msg);

/// Type define for mutable dictionary.
typedef NSMutableDictionary MKVContainer;

typedef NS_ENUM(int, UNMsgCallbackType)
{
    // The device is not able or allowed to make payments.
    UN_MSG_CBTYPE_CANNOT_MAKE_PAYMENTS = 1,
    // The product has been got successfully.
    UN_MSG_CBTYPE_GET_PRODUCT_SUCCESSFULLY = 2,
    // The product has failed to be got.
    UN_MSG_CBTYPE_FAIL_TO_GET_PRODUCT = 3,
    // There is no product for sale.
    UN_MSG_CBTYPE_NO_PRODUCT_FOR_SALE = 4,
    // A set of products have been got successfully.
    UN_MSG_CBTYPE_GET_PRODUCTS_SUCCESSFULLY = 5,
    // A set of products have failed to be got.
    UN_MSG_CBTYPE_FAIL_TO_GET_PRODUCTS = 6,
    // There is no products for sale.
    UN_MSG_CBTYPE_NO_PRODUCTS_FOR_SALE = 7,
    // The purchase has been deferred.
    UN_MSG_CBTYPE_PURCHASE_DEFERRED = 8,
    // The purchase is in progress.
    UN_MSG_CBTYPE_PURCHASE_IN_PROGRESS = 9,
    // The purchase has been cancelled by user.
    UN_MSG_CBTYPE_PURCHASE_CANCELLED = 10,
    // The purchase has failed.
    UN_MSG_CBTYPE_PURCHASE_FAILED = 11,
    // The purchase is successful.
    UN_MSG_CBTYPE_PURCHASE_SUCCEEDED = 12,
    // The purchase has failed to be restored.
    UN_MSG_CBTYPE_FAIL_TO_RESTORE_PURCHASE = 13,
    // The purchase has been restored successfully.
    UN_MSG_CBTYPE_PURCHASE_RESTORED = 14,
    // The receipt needs to be refreshed.
    UN_MSG_CBTYPE_REFRESH_RECEIPT = 15,
    // The receipt has failed to be refreshed.
    UN_MSG_CBTYPE_FAIL_TO_REFRESH_RECEIPT = 16,
    // The incompleted transactions were queried, then continue to verify receipt.
    UN_MSG_CBTYPE_INCOMPLETED_TRANSACTIONS = 17
};

/// The empty string for Objective-C.
extern NSString *const OCEmptyString;

extern void UNCallbackMessageDataToUnity(int msgCode, id msgData);

@interface UnityIAPConnector : NSObject

+ (NSString *)jsonWithObject:(id)object;
+ (id)objectWithJson:(NSString *)json;

@end

@interface NSMutableDictionary (UNTypeDef)

+ (instancetype)container;

@end
