## [英文文档（English Document）](README-en.md)

如果此项目能帮助到你，就请你给[一颗星](https://github.com/dgynfi/Unity_iOS_InAppPurchase)。谢谢！


## Unity_iOS_InAppPurchase

Unity加入了苹果的应用内购买。

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE)&nbsp;


## QQ群 (ID:614799921)

<div align=left>
&emsp; <img src="https://github.com/dgynfi/DYFStoreKit/raw/master/images/g614799921.jpg" width="30%" />
</div>


## 使用

### 1、添加 Objective-C 所需要的文件

在 Unity 工程中添加 Objective-C 所需要的文件，其目录结构如下：

objc ______ store_manager _________ DYFStoreManager.h      <br>
|                           |__________________ DYFStoreManager.mm <br>
|                                                                                                   <br>
|_______________ UnityIAPConnector.h      <br>
|_______________ UnityIAPConnector.mm  <br>

### 2、添加 cs 脚本

在 Unity 工程中添加 iOS 内购实现所需要的 cs 脚本。

unity_cs ______ U3DIAPManager.cs

### 3、添加 DYFStoreKit 目录文件

使用 `pod 'DYFStoreKit'` 添加最新版本的 iOS 内购库，或者手动添加 [DYFStoreKit](https://github.com/dgynfi/DYFStoreKit/tree/master/DYFStoreKit) 目录。

### 4、添加交易监听和其他

在 UnityAppController.mm 中添加头文件 `#import "DYFStoreManager.h"`

- 遵守协议

```
@interface UnityAppController() <DYFStoreAppStorePaymentDelegate>
@end
```

- 添加观察者、设置代理和数据持久

只要在返回前添加以下三段代码，其他代码不要改变。

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

- 你可以处理用户从App Store发起的购买 (iOS 11.0+)

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

### 5、注意事项

- 初始化 Unity 回调对象和函数

```
public void initUnityMsgCallback(string gameObject, string func)
{
    LogManager.Log("initUnityMsgCallback=" + gameObject + "," + func);
#if !UNITY_EDITOR && UNITY_IOS
    DYFInitUnityMsgCallback(gameObject, func);
#endif
}
```

- 单个商品购买

如果你的应用含有购买的 UI 界面和商品展示信息，用户就只需要选择购买。 缺点就是程序要做当地价格匹配。

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

当程序得到成功的回调时，就可以解析数据进行添加付款了。其他情况程序要对用户弹框提示。

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

- 请求多个商品并展示购买的 UI 界面

一次请求多个商品，通过工具获得商品的本地化信息。

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

当程序得到成功的回调时，就可以解析数据进行展示购买的 UI 界面。其他情况程序要对用户弹框提示。


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
        LogManager.Log ("parseProductList... jarr: " + jarr);

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

用户选择购买商品，用户 id 可根据需要进行设置。

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

- 恢复已经完成的交易，用户 id 可选

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

- 刷新票据

如果票据无效或丢失，就要刷新App Store票据。

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

-  票据验证

```
private void verifyReceipt(JObject jo)
{
    try {
        //LogManager.Log ("verifyReceipt... jo: " + jo.ToString());

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

    // Recommended reference link:
    // https://dgynfi.github.io/2016/10/16/in-app-purchase-complete-programming-guide-for-iOS/
    // https://www.jianshu.com/p/de030cd6e4a3
    // https://www.jianshu.com/p/1875e0c7ac5d
    
}
```

最后，在票据验证通过后，你要完成相应的交易。

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

- 查询未完成的交易

如果票据存在keychain并且没有完成验证，那么你需要查询出来，然后一一进行上报，直至交易，进而删除 keychain 中相应的记录。

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

## 要求

`Unity_iOS_InAppPurchase`需要`iOS 7.0`或更高版本和ARC。


## 欢迎反馈

如果你注意到任何问题，被卡住或只是想聊天，请随意创建一个问题。我很乐意帮助你。
