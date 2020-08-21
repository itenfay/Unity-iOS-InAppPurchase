## Unity-iOS-InAppPurchase

Unity implements Apple's in-app purchases for iOS.

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE)&nbsp;

[Chinese Instructions (中文说明)](README-zh.md)


## Group (ID:614799921)

<div align=left>
&emsp; <img src="https://github.com/dgynfi/DYFStoreKit/raw/master/images/g614799921.jpg" width="30%" />
</div>


## Usage

### 1. Add the required files for Objective-C.

You need to add the required files for Objective-C in Unity project, the directory structure is as follows:

objc __ store_manager __ DYFStoreManager.h <br>
| &emsp;&emsp;&emsp;&emsp;&emsp; |__ DYFStoreManager.mm <br>
|                        <br>
|__ UnityIAPConnector.h  <br>
|__ UnityIAPConnector.mm <br>

### 2. Add cs script.

You need to add the required cs script of in-app purchase for iOS in Unity project.

unity_cs __ UnityIAPManager.cs

### 3、Add `DYFStoreKit` directory files.

Use `pod 'DYFStoreKit'` to add the latest version of in-app purchas library for iOS, or manually add [DYFStoreKit](https://github.com/dgynfi/DYFStoreKit/tree/master/DYFStoreKit ) directory.

### 4、Adds the transaction observer and others.

Adds header file `#import "DYFStoreManager.h"` in UnityAppController.mm.

- Comply with the agreement.

```
@interface UnityAppController() <DYFStoreAppStorePaymentDelegate>
@end
```

- Adds the observer, set up the delegate and data persistence.

As long as you add the following three pieces of code before the method return value, the rest of the code does not change.

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        
    // Adds an observer that responds to updated transactions to the payment queue.
    // If an application quits when transactions are still being processed, those transactions are not lost. The next time the application launches, the payment queue will resume processing the transactions. Your application should always expect to be notified of completed transactions.
    // If more than one transaction observer is attached to the payment queue, no guarantees are made as to the order they will be called in. It is recommended that you use a single observer to process and finish the transaction.
    [DYFStore.defaultStore addPaymentTransactionObserver];
    
    // Sets the delegate processes the purchase which was initiated by user from the App Store.
    DYFStore.defaultStore.delegate = self;
    
    DYFStore.defaultStore.keychainPersister = [[DYFStoreKeychainPersistence alloc] init];
    
    return YES;
}
```

- You can process the purchase which was initiated by user from the App Store. (iOS 11.0+)

```
// Processes the purchase which was initiated by user from the App Store.
- (void)didReceiveAppStorePurchaseRequest:(SKPaymentQueue *)queue payment:(SKPayment *)payment forProduct:(SKProduct *)product {
    
    if (![DYFStore canMakePayments]) {
        // Tips: Your device is not able or allowed to make payments!
        return;
    }
    
    // Get account id from your own user system.
    //NSString *user_id = @"u144854433234";
    
    // You can choose to hash user_id.
    //NSString *userIdentifier = DYF_SHA256_HashValue(user_id);
    //DYFStoreLog(@"userIdentifier: %@", userIdentifier);
    
    [DYFStoreManager.shared addPayment:product.productIdentifier userIdentifier:nil];
}
```

### 5. Points for attention.

- Initializes the unity callback game object and function.

```
public void initUnityMsgCallback(string gameObject, string func)
{
    LogManager.Log("initUnityMsgCallback=" + gameObject + "," + func);
#if !UNITY_EDITOR && UNITY_IOS
    DYFInitUnityMsgCallback(gameObject, func);
#endif
}
```

- The purchase of a single product.

If your app contains purchased UI interface and product display information, users only need to choose to purchase. The disadvantage is that the program has to do local price matching.

```
public void retrieveProduct(string productId)
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        LogManager.Log("retrieveProduct=" + productId);
#if !UNITY_EDITOR && UNITY_IOS
        // Tips: show loading panel.
        DYFRetrieveProductFromAppStore(productId);
#endif
    }
}
```

When the program gets a successful callback, you can parse the data and add the payment. In other cases, the program should prompt the user with a pop-up box.

```
case (int)CallbackType.Action_GetProductSuccessfully:
{
    LogManager.Log ("CallbackType.Action_GetProductSuccessfully");

    string productId = (string)json["msg_data"]["p_id"];
    // You get this from your user system when you need it.
    string userId = null;
    addPayment(productId, userId);

    break;
}
````

- Requests multiple products and display the purchased UI interface.

You can request multiple products at a time and get the localized information of the product through the tool.

```
// You can either return the value or get a set of product identifiers from your server.
private JArray getJArrayOfProductIds()
{    
    JArray a = new JArray();
    foreach (var obj in LaunchMng.IAPDict) {
        a.Add(obj.Value);
    }
    return a;
}

// Converts JArray to json string.
private string getJsonOfProductIds()
{
    JArray a = getJArrayOfProductIds();
    string json = JsonConvert.SerializeObject(a);    
    return json;
}

public void retrieveProducts()
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        string jsonOfProductIds = getJsonOfProductIds()
        LogManager.Log("retrieveProducts=" + jsonOfProductIds);
#if !UNITY_EDITOR && UNITY_IOS
        // Tips: show loading panel.
        DYFRetrieveProductsFromAppStore(jsonOfProductIds);
#endif
    }
}
```

When the program gets a successful callback, it can parse the data to display the UI interface of the purchase. In other cases, the program should prompt the user with a pop-up box.

```
case (int)CallbackType.Action_GetProductsSuccessfully:
{
    LogManager.Log ("CallbackType.Action_GetProductsSuccessfully");

    JArray arr = JArray.Parse(json["msg_data"].ToString());
    parseProductList(arr);

    break;
}

private void parseProductList(JArray jarr)
{
    try {
        LogManager.Log ("parseProductList... jarr: " + jarr.ToString());

        for(int i = 0; i < jarr.Count; i++) {

            JObject jo = JObject.Parse(jarr[i].ToString());
            string productId = jo["p_id"].ToString();
            string title = jo["p_title"].ToString();
            string price = jo["p_price"].ToString();
            string localizedPrice = jo["p_localized_price"].ToString();
            string localizedDesc = jo["p_localized_desc"].ToString();

            LogManager.Log ("ProductList..." + i.ToString() + " productId: " + productId + 
                ";  title: " + title + "; price: " + price + "; localizedPrice: " + 
                localizedPrice + "; localizedDesc: " + localizedDesc);
        }
        // Call displayStorePanel(), The parameters need to be defined by you.
        // Waiting for the user to choose to buy goods, then call addPayment(...)
    } catch (System.Exception e) {
        LogManager.Log (e.ToString (), LogType.Fatal);
    }
}

private void displayStorePanel() {
    // After getting the products, then the store panel is displayed.
}
```

The user chooses to purchase product, and the user ID can be set as needed.

```
public void addPayment(string productId, string userId)
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        LogManager.Log("addPayment=" + productId + "," + userId);
#if !UNITY_EDITOR && UNITY_IOS
        // Tips: show loading panel.
        DYFAddPayment(productId, userId);
#endif
    }
}
```

- Restores the completed transactions, user ID is optional.

```
public void restoreTransactions(string userId)
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        LogManager.Log("DYFRestoreTransactions=", userId);
#if !UNITY_EDITOR && UNITY_IOS    
        // Tips: show loading panel.
        DYFRestoreTransactions(userId);
#endif
        LogManager.Log("Store start restoring completed transactions...", LogType.Normal);
    }
}
```

- Refreshes receipt.

If the receipt is invalid or missing, refresh the App Store's receipt.

```
case(int)CallbackType.Action_RefreshReceipt: 
{
    LogManager.Log ("CallbackType.Action_RefreshReceipt");

    // Tips: The receipt needs to be refreshed.
    string desc = (string)json["msg_data"]["m_desc"];
    LogManager.Log("err_desc=", desc);
    refreshReceipt()

    break;
}
```

```
public void refreshReceipt()
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
#if !UNITY_EDITOR && UNITY_IOS    
        // Tips: show loading panel.
        DYFRefreshReceipt();
#endif
        LogManager.Log("Store start refreshing receipt...", LogType.Normal);
    }
}
```

- Receipt verification.

```
private void verifyReceipt(JObject jo)
{
    try {
        LogManager.Log ("verifyReceipt... jo: " + jo.ToString());

        int state = int.Parse(jo["t_state"].ToString);
        string productId = jo["p_id"].ToString();
        string userId = jo["u_id"].ToString();
        string transId = jo["t_id"].ToString();
        string transTimestamp = jo["t_ts"].ToString();
        string orgTransId = jo["orgt_id"].ToString();
        string orgTransTimestamp = jo["orgt_ts"].ToString();
        string base64EncodedReceipt = jo["t_receipt"].ToString();

        // You can also add the bundle identifier.
        requestToVerifyReceipt(productId, transId, base64EncodedReceipt, userId, transTimestamp, orgTransId, orgTransTimestamp);

    } catch (System.Exception e) {
        LogManager.Log (e.ToString (), LogType.Fatal);
    }
}

private void requestToVerifyReceipt(string productId, string transId, string base64EncodedReceipt, 
    string userId, string transTimestamp, string orgTransId, string orgTransTimestamp) {

    // The URL for receipt verification.
    // Sandbox: "https://sandbox.itunes.apple.com/verifyReceipt"
    // Production: "https://buy.itunes.apple.com/verifyReceipt"

    // Finally, you call this method to complete the transaction.
    // finishTransaction(transactionId); finishTransaction(orgTransactionId); 

    // Recommended reference links:
    // https://dgynfi.github.io/2016/10/16/in-app-purchase-complete-programming-guide-for-iOS/
    // https://dgynfi.github.io/2016/10/12/how-to-easily-complete-in-app-purchase-configuration-for-iOS/
    // https://www.jianshu.com/p/de030cd6e4a3
    // https://www.jianshu.com/p/1875e0c7ac5d
    
    // Performs http request or builds tcp/udp connection.
}
```

Finally, after the receipt is verified, you need to complete the corresponding transaction.

```
public void finishTransaction(string transactionId)
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        LogManager.Log("finishTransaction", LogType.Normal);
#if !UNITY_EDITOR && UNITY_IOS                
        DYFFinishTransaction(transactionId);
#endif
    }
}
```

- Queries those incompleted transactions.

If there are the receipts in keychain and the receipt verification has not been completed, you need to query them out, and then report them one by one until the transaction, and then delete the corresponding record in the keychain.

```
public void queryIncompletedTransactions()
{
    if (Application.platform != RuntimePlatform.OSXEditor) {
        LogManager.Log("queryIncompletedTransactions", LogType.Normal);
#if !UNITY_EDITOR && UNITY_IOS                
        DYFQueryIncompletedTransactions();
#endif
    }
}
```


## Recommended Reference Links

- [https://dgynfi.github.io/2016/10/16/in-app-purchase-complete-programming-guide-for-iOS/](https://dgynfi.github.io/2016/10/16/in-app-purchase-complete-programming-guide-for-iOS/)
- [https://dgynfi.github.io/2016/10/12/how-to-easily-complete-in-app-purchase-configuration-for-iOS/](https://dgynfi.github.io/2016/10/12/how-to-easily-complete-in-app-purchase-configuration-for-iOS/)
- [https://www.jianshu.com/p/de030cd6e4a3](https://www.jianshu.com/p/de030cd6e4a3)
- [https://www.jianshu.com/p/1875e0c7ac5d](https://www.jianshu.com/p/1875e0c7ac5d)


## Requirements

`Unity_iOS_InAppPurchase` requires `iOS 7.0` or above and `ARC`.


## Feedback is welcome

If you notice any issue, got stuck or just want to chat feel free to create an issue. I will be happy to help you.
