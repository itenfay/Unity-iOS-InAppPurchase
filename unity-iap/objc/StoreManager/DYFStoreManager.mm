//
//  DYFStoreManager.m
//
//  Created by chenxing on 2014/11/4. ( https://github.com/chenxing640/Unity-iOS-InAppPurchase )
//  Copyright © 2014 chenxing. All rights reserved.
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

#import "DYFStoreManager.h"
#import "UnityIAPConnector.h"
#import "DYFStore.h"
#import "DYFStoreUserDefaultsPersistence.h"
//#import "NSObject+DYFAdd.h" //Optional
//#import "DYFStoreReceiptVerifier.h" //Optional

//@interface DYFStoreManager () <DYFStoreReceiptVerifierDelegate> //Optional
@interface DYFStoreManager ()

@property (nonatomic, strong) DYFStoreNotificationInfo *purchaseInfo;
@property (nonatomic, strong) DYFStoreNotificationInfo *downloadInfo;

//@property (nonatomic, strong) DYFStoreReceiptVerifier *receiptVerifier;

@end

@implementation DYFStoreManager

// Provides a global static variable.
static DYFStoreManager *_instance = nil;

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    
}

- (void)addStoreObserver
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(processPurchaseNotification:) name:DYFStorePurchasedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(processDownloadNotification:) name:DYFStoreDownloadedNotification object:nil];
}

- (void)removeStoreObserver
{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:DYFStorePurchasedNotification
                                                object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:DYFStoreDownloadedNotification
                                                object:nil];
}

- (void)addPayment:(NSString *)productIdentifier
{
    [self addPayment:productIdentifier userIdentifier:nil];
}

- (void)addPayment:(NSString *)productIdentifier userIdentifier:(NSString *)userIdentifier
{
    // Initiate purchase request.
    //[self showLoading:@"Waiting..."];
    [DYFStore.defaultStore purchaseProduct:productIdentifier userIdentifier:userIdentifier];
}

- (void)restoreTransactions
{
    [self restoreTransactions:nil];
}

- (void)restoreTransactions:(NSString *)userIdentifier
{
    DYFStoreLog(@"userIdentifier: %@", userIdentifier);
    //[self showLoading:@"Restoring..."];
    [DYFStore.defaultStore restoreTransactions:userIdentifier];
}

- (void)processDeferredPurchase
{
    MKVContainer *item = [MKVContainer container];
    [item setValue:@"The purchase has been deferred" forKey:@"m_desc"];
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_PURCHASE_DEFERRED, item);
}

- (void)processPurchaseInProgress
{
    MKVContainer *item = [MKVContainer container];
    [item setValue:@"The purchase is in progress" forKey:@"m_desc"];
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_PURCHASE_IN_PROGRESS, item);
}

- (void)processCancelledPurchase
{
    MKVContainer *item = [MKVContainer container];
    [item setValue:@"The purchase has been cancelled by user" forKey:@"m_desc"];
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_PURCHASE_CANCELLED, item);
}

- (void)processFailedPurchase
{
    int msgCode = 0;
    if (self.purchaseInfo.state == DYFStorePurchaseStateFailed) {
        msgCode = UN_MSG_CBTYPE_PURCHASE_FAILED;
    } else {
        msgCode = UN_MSG_CBTYPE_FAIL_TO_RESTORE_PURCHASE;
    }
    
    NSInteger code = self.purchaseInfo.error.code;
    NSString *value = self.purchaseInfo.error.userInfo[NSLocalizedDescriptionKey];
    NSString *msg = value ?: self.purchaseInfo.error.localizedDescription;
    
    MKVContainer *item = [MKVContainer container];
    [item setValue:@(code) forKey:@"err_code"];
    [item setValue:msg forKey:@"err_desc"];
    UNCallbackMessageDataToUnity(msgCode, item);
}

- (void)processPurchaseNotification:(NSNotification *)notification
{
    //[self hideLoading];
    self.purchaseInfo = notification.object;
    switch (self.purchaseInfo.state) {
        case DYFStorePurchaseStatePurchasing:
            //[self showLoading:@"Purchasing..."];
            [self processPurchaseInProgress];
            break;
        case DYFStorePurchaseStateCancelled:
            // The user cancel the purchase.
            //[self sendNotice:@"You cancel the purchase"];
            [self processCancelledPurchase];
            break;
        case DYFStorePurchaseStateFailed:
            //[self sendNotice:[NSString stringWithFormat:@"An error occurred, code is %zi.", self.purchaseInfo.error.code]];
            [self processFailedPurchase];
            break;
        case DYFStorePurchaseStateSucceeded:
        case DYFStorePurchaseStateRestored:
            [self completePayment];
            break;
        case DYFStorePurchaseStateRestoreFailed:
            //[self sendNotice:[NSString stringWithFormat:@"An error occurred, code is %zi.", self.purchaseInfo.error.code]];
            [self processFailedPurchase];
            break;
        case DYFStorePurchaseStateDeferred:
            // Deferred
            [self processDeferredPurchase];
            break;
        default:
            break;
    }
}

- (void)processDownloadNotification:(NSNotification *)notification
{
    self.downloadInfo = notification.object;
    switch (self.downloadInfo.downloadState) {
        case DYFStoreDownloadStateStarted:
            DYFStoreLog(@"The download started");
            break;
        case DYFStoreDownloadStateInProgress:
            DYFStoreLog(@"The download progress: %.2f%%", self.downloadInfo.downloadProgress);
            break;
        case DYFStoreDownloadStateCancelled:
            DYFStoreLog(@"The download cancelled");
            break;
        case DYFStoreDownloadStateFailed:
            DYFStoreLog(@"The download failed");
            break;
        case DYFStoreDownloadStateSucceeded:
            DYFStoreLog(@"The download succeeded: 100%%");
            break;
        default:
            break;
    }
}

- (void)completePayment
{
    DYFStoreNotificationInfo *info = self.purchaseInfo;
    DYFStoreUserDefaultsPersistence *persister = [[DYFStoreUserDefaultsPersistence alloc] init];
    
    NSString *identifier = info.transactionIdentifier;
    if (![persister containsTransaction:identifier]) {
        [self storeReceipt];
        return;
    }
    
    DYFStoreTransaction *transaction = [persister retrieveTransaction:identifier];
    [self verifyReceipt:transaction];
}

- (void)storeReceipt
{
    DYFStoreLog();
    NSURL *receiptURL = DYFStore.receiptURL;
    NSData *data = [NSData dataWithContentsOfURL:receiptURL];
    if (!data || data.length == 0) {
        [self sendNoticeToRefreshReceipt];
        return;
    }
    
    DYFStoreNotificationInfo *info = self.purchaseInfo;
    DYFStoreUserDefaultsPersistence *persister = [[DYFStoreUserDefaultsPersistence alloc] init];
    
    DYFStoreTransaction *transaction = [[DYFStoreTransaction alloc] init];
    if (info.state == DYFStorePurchaseStateSucceeded) {
        transaction.state = DYFStoreTransactionStatePurchased;
    } else if (info.state == DYFStorePurchaseStateRestored) {
        transaction.state = DYFStoreTransactionStateRestored;
    }
    
    transaction.productIdentifier = info.productIdentifier;
    transaction.userIdentifier = info.userIdentifier;
    transaction.transactionIdentifier = info.transactionIdentifier;
    transaction.transactionTimestamp = info.transactionDate.timestamp;
    transaction.originalTransactionTimestamp = info.originalTransactionDate.timestamp;
    transaction.originalTransactionIdentifier = info.originalTransactionIdentifier;
    
    transaction.transactionReceipt = data.base64EncodedString;
    [persister storeTransaction:transaction];
    
    [self verifyReceipt:transaction];
}

- (void)sendNoticeToRefreshReceipt
{
    MKVContainer *item = [MKVContainer container];
    [item setValue:@"The receipt needs to be refreshed" forKey:@"m_desc"];
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_REFRESH_RECEIPT, item);
}

- (void)refreshReceipt
{
    DYFStoreLog();
    //[self showLoading:@"Refresh receipt..."];
    [DYFStore.defaultStore refreshReceiptOnSuccess:^{
        [self storeReceipt];
    } failure:^(NSError *error) {
        [self failToRefreshReceipt:error];
    }];
}

- (void)failToRefreshReceipt:(NSError *)error
{
    DYFStoreLog();
    //[self hideLoading];
    MKVContainer *item = [MKVContainer container];
    [item setValue:@(error.code) forKey:@"err_code"];
    [item setValue:error.localizedDescription forKey:@"err_desc"];
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_FAIL_TO_REFRESH_RECEIPT, item);
}

- (void)verifyReceipt:(DYFStoreTransaction *)transaction
{
    NSUInteger state = transaction.state;
    NSString *productId = transaction.productIdentifier;
    NSString *userId = transaction.userIdentifier;
    NSString *transId = transaction.transactionIdentifier;
    NSString *transTs = transaction.transactionTimestamp;
    NSString *orgTransId = transaction.originalTransactionIdentifier;
    NSString *orgTransTs = transaction.originalTransactionTimestamp;
    NSString *receipt = transaction.transactionReceipt;
    
    DYFStoreLog(@"transaction.state: %zi", state);
    DYFStoreLog(@"transaction.productIdentifier: %@", productId);
    DYFStoreLog(@"transaction.userIdentifier: %@", userId);
    DYFStoreLog(@"transaction.transactionIdentifier: %@", transId);
    DYFStoreLog(@"transaction.transactionTimestamp: %@", transTs);
    DYFStoreLog(@"transaction.originalTransactionIdentifier: %@", orgTransId);
    DYFStoreLog(@"transaction.originalTransactionTimestamp: %@", orgTransTs);
    DYFStoreLog(@"transaction.transactionReceipt: %@", receipt);
    
    int msgCode = 0;
    if (state == (NSUInteger)DYFStoreTransactionStatePurchased) {
        msgCode = UN_MSG_CBTYPE_PURCHASE_SUCCEEDED;
    } else {
        msgCode = UN_MSG_CBTYPE_PURCHASE_RESTORED;
    }
    
    MKVContainer *item = [MKVContainer container];
    [item setValue:@(state) forKey:@"t_state"];
    [item setValue:productId forKey:@"p_id"];
    [item setValue:userId ?: [NSNull null] forKey:@"u_id"];
    [item setValue:transId forKey:@"t_id"];
    [item setValue:transTs forKey:@"t_ts"];
    [item setValue:orgTransId ?: [NSNull null] forKey:@"orgt_id"];
    [item setValue:orgTransTs ?: [NSNull null] forKey:@"orgt_ts"];
    [item setValue:receipt forKey:@"t_receipt"];
    UNCallbackMessageDataToUnity(msgCode, item);
}

- (void)queryIncompletedTransactions
{
    DYFStoreUserDefaultsPersistence *persister = [[DYFStoreUserDefaultsPersistence alloc] init];
    NSArray<DYFStoreTransaction *> *arr = [persister retrieveTransactions];
    if (arr && arr.count > 0) {
        NSMutableArray *mArr = [NSMutableArray array];
        for (DYFStoreTransaction *t in arr) {
            MKVContainer *item = [MKVContainer container];
            [item setValue:@(t.state) forKey:@"t_state"];
            [item setValue:t.productIdentifier forKey:@"p_id"];
            [item setValue:t.userIdentifier ?: [NSNull null] forKey:@"u_id"];
            [item setValue:t.transactionIdentifier forKey:@"t_id"];
            [item setValue:t.transactionTimestamp forKey:@"t_ts"];
            [item setValue:t.originalTransactionIdentifier ?: [NSNull null] forKey:@"orgt_id"];
            [item setValue:t.originalTransactionTimestamp ?: [NSNull null] forKey:@"orgt_ts"];
            [item setValue:t.transactionReceipt forKey:@"t_receipt"];
            [mArr addObject:item];
        }
        UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_INCOMPLETED_TRANSACTIONS, mArr);
        return;
    }
    
    UNCallbackMessageDataToUnity(UN_MSG_CBTYPE_INCOMPLETED_TRANSACTIONS, OCEmptyString);
}

//- (DYFStoreReceiptVerifier *)receiptVerifier
//{
//    if (!_receiptVerifier) {
//        _receiptVerifier = [[DYFStoreReceiptVerifier alloc] init];
//        _receiptVerifier.delegate = self;
//    }
//    return _receiptVerifier;
//}

// It is better to use your own server to obtain the parameters uploaded from the client to verify the receipt from the app store server (C -> Uploaded Parameters -> S -> App Store S -> S -> Receive And Parse Data -> C).
// If the receipts are verified by your own server, the client needs to upload these parameters, such as: "transaction identifier, bundle identifier, product identifier, user identifier, shared sceret(Subscription), receipt(Safe URL Base64), original transaction identifier(Optional), original transaction time(Optional) and the device information, etc.".
//- (void)verifyReceiptByClient:(NSData *)receiptData
//{
//    DYFStoreLog();
//    [self hideLoading];
//    [self showLoading:@"Verify receipt..."];
//
//    NSData *data = receiptData ?: [NSData dataWithContentsOfURL:DYFStore.receiptURL];
//    DYFStoreLog(@"data: %@", data);
//
//    [self.receiptVerifier verifyReceipt:data];
//    // Only used for receipts that contain auto-renewable subscriptions.
//    //[_receiptVerifier verifyReceipt:data sharedSecret:@"A43512564ACBEF687924646CAFEFBDCAEDF4155125657"];
//}

//- (void)retryToVerifyReceipt
//{
//    DYFStoreNotificationInfo *info = self.purchaseInfo;
//    DYFStoreUserDefaultsPersistence *persister = [[DYFStoreUserDefaultsPersistence alloc] init];
//
//    NSString *identifier = info.transactionIdentifier;
//    DYFStoreTransaction *transaction = [persister retrieveTransaction:identifier];
//    NSData *receiptData = transaction.transactionReceipt.base64DecodedData;
//    [self verifyReceiptByClient:receiptData];
//}

//- (void)verifyReceiptDidFinish:(nonnull DYFStoreReceiptVerifier *)verifier didReceiveData:(nullable NSDictionary *)data {
//    DYFStoreLog(@"data: %@", data);
//    [self hideLoading];
//    [self showTipsMessage:@"Purchase Successfully"];
//    // Tips: Purchase Successfully!
//}

//- (void)verifyReceipt:(nonnull DYFStoreReceiptVerifier *)verifier didFailWithError:(nonnull NSError *)error {
//    // Prints the reason of the error.
//    DYFStoreLog(@"error: %zi, %@", error.code, error.localizedDescription);
//    [self hideLoading];
//
//    // An error occurs that has nothing to do with in-app purchase. Maybe it's the internet.
//    if (error.code < 21000) {
//        // After several attempts, you can cancel refreshing receipt.
//        //Fail to verify receipt!
//        //[self retryToVerifyReceipt];
//        return;
//    }
//
//    // Tips: Fail to purchase the product!
//}

//- (void)sendNotice:(NSString *)message
//{
//    [self showAlertWithTitle:NSLocalizedStringFromTable(@"Notification", nil, @"")
//                     message:message
//           cancelButtonTitle:nil
//                      cancel:NULL
//          confirmButtonTitle:NSLocalizedStringFromTable(@"I see", nil, @"")
//                     execute:^(UIAlertAction *action) {
//        DYFStoreLog(@"Alert action title: %@", action.title);
//    }];
//}

- (void)dealloc
{
    
}

@end
