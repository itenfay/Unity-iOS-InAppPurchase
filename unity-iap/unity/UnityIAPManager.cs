/// 
/// File Name: UnityIAPManager.cs
/// 
/// Author: chenxing
///
/// Brief:
///   Unity implements Apple's in-app purchases for iOS.
///
/// Log:
///   1. created, 2020-04-16, chenxing.
///

using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;

// Note: You need to change "com.dl.core.SingletonObject" to your's package.
public class UnityIAPManager : com.dl.core.SingletonObject<UnityIAPManager>
{

	protected override void Spawn ()
	{
		base.Spawn ();
		this.gameObject.name = "Main";
	}
	
	public enum CallbackType
	{
		Action_CannotMakePayments 	   = 1,  // The device is not able or allowed to make payments.
		Action_GetProductSuccessfully  = 2,  // The product has been got successfully.
		Action_FailToGetProduct 	   = 3,  // The product has failed to be got. 
		Action_NoProductForSale 	   = 4,  // There is no product for sale.
		Action_GetProductsSuccessfully = 5,  // A set of products have been got successfully.
		Action_FailToGetProducts 	   = 6,  // A set of products have failed to be got.
		Action_NoProductsForSale 	   = 7,  // There is no products for sale.
		Action_PurchaseDeferred	   	   = 8,  // The purchase has been deferred.
		Action_PurchaseInProgress      = 9,  // The purchase is in progress.
		Action_PurchaseCancelled	   = 10, // The purchase has been cancelled by user.
		Action_PurchaseFailed	   	   = 11, // The purchase has failed.
		Action_PurchaseSucceeded	   = 12, // The purchase is successful.
		Action_FailToRestorePurchase   = 13, // The purchase has failed to be restored.
		Action_PurchaseRestored	   	   = 14, // The purchase has been restored successfully.
		Action_RefreshReceipt	   	   = 15, // The receipt needs to be refreshed.
		Action_FailToRefreshReceipt	   = 16, // The receipt has failed to be refreshed.
		Action_IncompletedTransactions = 17  // The incompleted transactions were queried, then continue to verify receipt.
	}

	public static bool canMakePayments = false;

#if !UNITY_EDITOR && UNITY_IOS

	// Initializes message callback for Unity.
	[DllImport("__Internal")]    
	private static extern void DYFInitUnityMsgCallback(string gameObject, string func);

	// Retrieves a product from App Store and adds the payment.
	[DllImport("__Internal")]
	private static extern void DYFRetrieveProductFromAppStore(string productId);

	// Retrieves a set of products from App Store and displays store UI, then add the payment.
	[DllImport("__Internal")]
	private static extern void DYFRetrieveProductsFromAppStore(string jsonForProductIds);

	// Adds the payment of a product.
	[DllImport("__Internal")]    
	private static extern void DYFAddPayment(string productId, string userId);

	// Restores previously completed purchases.
	[DllImport("__Internal")]
	private static extern void DYFRestoreTransactions(string userId);

	// Refreshes the App Store receipt in case the receipt is invalid or missing.
	[DllImport("__Internal")]
	private static extern void DYFRefreshReceipt();

	// Completes a pending transaction.
	[DllImport("__Internal")]
	private static extern void DYFFinishTransaction(string transactionId, string originalTransactionId);

	// Completes a pending transaction.
	[DllImport("__Internal")]
	private static extern void DYFFinishTransaction_(string transactionId);

	// Queries those incompleted transactions.
	[DllImport("__Internal")]
	private static extern void DYFQueryIncompletedTransactions();
	
#endif

	// Note: You can get the array from your server or write the fixed values.
	private JArray getJArrayOfProductIds()
	{	
		JArray a = new JArray();
		a.Add("com.xx.gm.pack1");
		a.Add("com.xx.gm.pack2");
		a.Add("com.xx.gm.pack3");
		a.Add("com.xx.gm.pack4");
		a.Add("com.xx.gm.pack5");
		a.Add("com.xx.gm.pack6");
		// ......
		return a;
	}

	// Note: You can get a json string from a jarray.
	private string getJsonOfProductIds()
	{
		JArray a = getJArrayOfProductIds();
		string json = JsonConvert.SerializeObject(a);	
		return json;
	}

	public void initUnityMsgCallback(string gameObject, string func)
	{
		LogManager.Log("initUnityMsgCallback=" + gameObject + "," + func);
		#if !UNITY_EDITOR && UNITY_IOS
		// UMessageCallback(string msg)
		DYFInitUnityMsgCallback(gameObject, func); 
		#endif
	}

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

	public void finishTransaction(string transactionId, string originalTransactionId)
	{
		if (Application.platform != RuntimePlatform.OSXEditor) {
			LogManager.Log("finishTransaction", LogType.Normal);
			#if !UNITY_EDITOR && UNITY_IOS				
			DYFFinishTransaction(transactionId, originalTransactionId);
			#endif
		}
	}

	public void finishTransaction_(string transactionId)
	{
		if (Application.platform != RuntimePlatform.OSXEditor) {
			LogManager.Log("finishTransaction_", LogType.Normal);
			#if !UNITY_EDITOR && UNITY_IOS				
			DYFFinishTransaction_(transactionId);
			#endif
		}
	}

	public void queryIncompletedTransactions()
	{
		if (Application.platform != RuntimePlatform.OSXEditor) {
			LogManager.Log("queryIncompletedTransactions", LogType.Normal);
			#if !UNITY_EDITOR && UNITY_IOS				
			DYFQueryIncompletedTransactions();
			#endif
		}
	}
	
	public void UMessageCallback(string msg)
	{
		LogManager.Log ("UMessageCallback: " + msg, LogType.Normal);

		if (msg.Length == 0) {
			// You need to present a panel to prompt the user.
			// Tips: The data occurs an error.
			return;
		}

		try {
			JObject json = (JObject)JsonConvert.DeserializeObject(msg);
			int act = -1;
			if (int.TryParse(json["msg_code"].ToString (), out act)) {

				switch (act) {
					case (int)CallbackType.Action_CannotMakePayments:
					{
						LogManager.Log ("CallbackType.Action_CannotMakePayments");
						// Tips: The device is not able or allowed to make payments.
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_desc, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}

					case (int)CallbackType.Action_GetProductSuccessfully:
					{
						LogManager.Log ("CallbackType.Action_GetProductSuccessfully");
						string productId = (string)json["msg_data"]["p_id"];
						// You get this from your user system when you need it.
						string userId = null;
						addPayment(productId, userId);
						break;
					}

					case (int)CallbackType.Action_FailToGetProduct:
					{
						LogManager.Log ("CallbackType.Action_FailToGetProduct");

						// Tips: The product has failed to be got.
						string err_code = json["msg_data"]["err_desc"].ToString();
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_code, err_desc, LogType.Error);
						// You need to present a panel to prompt the user.

						break;
					}

					case (int)CallbackType.Action_NoProductForSale:
					{
						LogManager.Log ("CallbackType.Action_NoProductForSale");
						// Tips: There is no product for sale.
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_desc, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}
					
					case (int)CallbackType.Action_GetProductsSuccessfully:
					{
						LogManager.Log ("CallbackType.Action_GetProductsSuccessfully");
						JArray arr = JArray.Parse(json["msg_data"].ToString());
						parseProductList(arr);
						break;
					}

					case (int)CallbackType.Action_FailToGetProducts:
					{
						LogManager.Log ("CallbackType.Action_FailToGetProducts");
						// Tips: A set of products have failed to be got.
						string err_code = json["msg_data"]["err_desc"].ToString();
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_code, err_desc, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_NoProductsForSale:
					{
						LogManager.Log ("CallbackType.Action_NoProductsForSale");
						// Tips: There is no products for sale.
						string err_desc = (string)json["msg_data"]["err_desc"];
						string invalid_ids = (string)json["msg_data"]["invalid_ids"];
						LogManager.Log("err_desc=", err_desc, invalid_ids, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_PurchaseDeferred: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseDeferred");

						// Tips: The purchase has been deferred.
						string desc = (string)json["msg_data"]["m_desc"];
						LogManager.Log("err_desc=", desc);
						// Yon can choose to process the program.

						break;
					}

					case(int)CallbackType.Action_PurchaseInProgress: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseInProgress");
						// Tips: The purchase is in progress.
						string desc = (string)json["msg_data"]["m_desc"];
						LogManager.Log("err_desc=", desc);
						// You can present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_PurchaseCancelled: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseCancelled");
						// Tips: The purchase has been cancelled by user.
						string desc = (string)json["msg_data"]["m_desc"];
						LogManager.Log("err_desc=", desc);
						// You need to present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_PurchaseFailed: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseFailed");
						// Tips: The purchase has failed.
						string err_code = json["msg_data"]["err_desc"].ToString();
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_code, err_desc, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_PurchaseSucceeded: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseSucceeded");
						// Tips: The purchase has been completed.
						JObject obj = JObject.Parse(json["msg_data"].ToString());
						// You can verify the receipt.
						verifyReceipt(obj);
						break;
					}

					case(int)CallbackType.Action_FailToRestorePurchase: 
					{
						LogManager.Log ("CallbackType.Action_FailToRestorePurchase");
						// Tips: The purchase has failed to be restored.
						string err_code = json["msg_data"]["err_desc"].ToString();
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_code, err_desc, LogType.Error);
						// You need to present a panel to prompt the user.
						break;
					}

					case(int)CallbackType.Action_PurchaseRestored: 
					{
						LogManager.Log ("CallbackType.Action_PurchaseRestored");
						// Tips: The purchase has been restored successfully.
						JObject obj = JObject.Parse(json["msg_data"].ToString());
						// You can verify the receipt.
						verifyReceipt(obj);
						break;
					}

					case(int)CallbackType.Action_RefreshReceipt: 
					{
						LogManager.Log ("CallbackType.Action_RefreshReceipt");
						// Tips: The receipt needs to be refreshed.
						string desc = (string)json["msg_data"]["m_desc"];
						LogManager.Log("err_desc=", desc);
						refreshReceipt()
						break;
					}

					case(int)CallbackType.Action_FailToRefreshReceipt: 
					{
						LogManager.Log ("CallbackType.Action_FailToRefreshReceipt");
						// Tips: The receipt has failed to be refreshed.
						string err_code = json["msg_data"]["err_desc"].ToString();
						string err_desc = (string)json["msg_data"]["err_desc"];
						LogManager.Log("err_desc=", err_code, err_desc, LogType.Error);
						// You need to present a panel to inform the user to refresh receipt again.
						// If this is not done, this transaction will not be completed.
						// refreshReceipt()
						break;
					}

					case(int)CallbackType.Action_IncompletedTransactions: 
					{
						LogManager.Log ("CallbackType.Action_IncompletedTransactions");
						// Tips: The receipt has failed to be refreshed.
						string data = json["msg_data"].ToString();
						if (data.Length != 0) {
							LogManager.Log("data=", data, LogType.Normal);
							JArray arr = JArray.Parse(data)
							for(int i = 0; i < arr.Count; i++) {
								JObject jo = JObject.Parse(jarr[i].ToString());
								int state = int.Parse(jo["t_state"].ToString);
								string productId = jo["p_id"].ToString();
								string userId = jo["u_id"].ToString();
								string transId = jo["t_id"].ToString();
								string transTimestamp = jo["t_ts"].ToString();
								string orgTransId = jo["orgt_id"].ToString();
								string orgTransTimestamp = jo["orgt_ts"].ToString();
								string base64EncodedReceipt = jo["t_receipt"].ToString();
								requestToVerifyReceipt(productId, transId, base64EncodedReceipt, userId, transTimestamp, orgTransId, orgTransTimestamp);
							}
						}
						break;
					}

					default:
						break;
				}
			}
		} catch (System.Exception e) {
			LogManager.Log ("exception=" + e.ToString (), LogType.Fatal);
		}
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

	private void displayStorePanel() 
	{
		// After getting the products, then the store panel is displayed.
	}

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
		// https://chenxing640.github.io/2016/10/16/in-app-purchase-complete-programming-guide-for-iOS/
		// https://chenxing640.github.io/2016/10/12/how-to-easily-complete-in-app-purchase-configuration-for-iOS/
		// https://www.jianshu.com/p/de030cd6e4a3
		// https://www.jianshu.com/p/1875e0c7ac5d
		
		// Performs http request or builds tcp/udp connection.
	}

}
