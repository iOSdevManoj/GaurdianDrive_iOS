//
//  SubscriptionListVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 05/02/26.
//

import UIKit
import StoreKit

class SubscriptionListVC: UIViewController {

    //Outlets....
    @IBOutlet var btnMonthly: UIButton!
    @IBOutlet var btnYearly: UIButton!
    @IBOutlet weak var viewForPaymentDetails: UIView!
    @IBOutlet var collViewPlanList: UICollectionView!

    //Variables..
    var isMonthlySelected = true
    var arrSubsDataMonthly = [SubscriptionModel]()
    var arrSubsDataYearly = [SubscriptionModel]()
    var selectedIndex = 99

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialization()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
    }
//    override func viewWillDisappear(_ animated: Bool) {
//        SKPaymentQueue.default().remove(self)
//        self.productsRequest.delegate = nil
//        self.productsRequest.cancel()
//    }
//    deinit {
//        SKPaymentQueue.default().remove(self)
//    }
}

//MARK: - Initialisation...
extension SubscriptionListVC
{
    func initialization() {
        
        self.collViewPlanList.register(UINib(nibName: "CellForPlans", bundle: nil), forCellWithReuseIdentifier: "CellForPlans")

        self.arrSubsDataMonthly.removeAll()
        self.arrSubsDataYearly.removeAll()
        self.setupAllInAppPurchaseProducts()

        // ✅ IAP Codes
        self.allSubscriptionMehodAndResponse()

    }
    
    func setupAllInAppPurchaseProducts()
    {
        let arry4Data1 = [["name":"Basic","productIdentifry":oneChild_1Month,"price":"$4.99","childCount":"1","yearly":"$55.99"],["name":"Family2","productIdentifry":twoChild_1Month,"price":"$5.99","childCount":"2","yearly":"$65.99"],["name":"Family3","productIdentifry":threeChild_1Month,"price":"$6.99","childCount":"3","yearly":"$75.99"],["name":"Family4","productIdentifry":fourChild_1Month,"price":"$7.99","childCount":"4","yearly":"$85.99"]]
        let arry4Data2 = [["name":"Basic","productIdentifry":oneChild_Yearly,"price":"$55.99","childCount":"1"],["name":"Family2","productIdentifry":twoChild_Yearly,"price":"$65.99","childCount":"2"],["name":"Family3","productIdentifry":threeChild_Yearly,"price":"$75.99","childCount":"3"],["name":"Family4","productIdentifry":fourChild_Yearly,"price":"$85.99","childCount":"4"]]
        
        self.arrSubsDataMonthly = arry4Data1.map { SubscriptionModel(dictData: $0 as NSDictionary) }
        self.arrSubsDataYearly  = arry4Data2.map { SubscriptionModel(dictData: $0 as NSDictionary) }
        self.collViewPlanList.reloadData()
    }
    
    //IAP structures and call back...
    func allSubscriptionMehodAndResponse()
    {
        IAPManager.shared.onPurchaseSuccess = { [weak self] productId, transactionId, originalTransactionId, expiry in
            guard let self = self else { return }

            print("✅ SUCCESS:", productId, transactionId, originalTransactionId ,expiry as Any)

            var childCount = ""
            if self.isMonthlySelected {
                childCount = self.arrSubsDataMonthly.first(where: { $0.productIdentifry == productId })?.childCount ?? ""
            } else {
                childCount = self.arrSubsDataYearly.first(where: { $0.productIdentifry == productId })?.childCount ?? ""
            }
            appDelegate.showHud()
            self.apiCallForSubscription(
                aTransactionID: originalTransactionId,
                aChildCount: childCount,
                aBunddleID:"org.app.GaurdianDrive"
            )
        }
        
        IAPManager.shared.onRestoreSuccess = { [weak self] productId, transactionId, originalTransactionId, expiry in
            guard let self = self else { return }

            print("♻️ RESTORE SUCCESS:", productId, transactionId, originalTransactionId, expiry as Any)

            let childCount = self.getChildCount(productId: productId)
            
            appDelegate.showHud()

            self.apiCallForSubscription(
                aTransactionID: originalTransactionId,
                aChildCount: childCount,
                aBunddleID: "org.app.GaurdianDrive"
            )
        }

        IAPManager.shared.onPurchaseFailed = { error in
            appDelegate.hideHud()
            print("❌ FAILED:", error)
        }

        // ✅ Fetch Products (async)

        Task {
            await IAPManager.shared.fetchProducts(ids: [
                oneChild_1Month,
                twoChild_1Month,
                threeChild_1Month,
                fourChild_1Month,
                oneChild_Yearly,
                twoChild_Yearly,
                threeChild_Yearly,
                fourChild_Yearly
            ])

            print("Products loaded:", IAPManager.shared.products.count)
        }
    }
    
    func getChildCount(productId: String) -> String {

        if let monthly = arrSubsDataMonthly.first(where: { $0.productIdentifry == productId }) {
            return monthly.childCount
        }

        if let yearly = arrSubsDataYearly.first(where: { $0.productIdentifry == productId }) {
            return yearly.childCount
        }

        return ""
    }
}

//MARK: - Click Events.....
extension SubscriptionListVC
{
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToPurchase(_ sender: UIButton) {
        self.view.endEditing(true)

           if selectedIndex == 99 {
               popupAlert(title: "Select Plan",
                          message: "Please select a subscription plan first.",
                          actionTitles: ["OK"],
                          actions: [{ _ in }, nil])
               return
           }

           let productID = isMonthlySelected
               ? arrSubsDataMonthly[selectedIndex].productIdentifry
               : arrSubsDataYearly[selectedIndex].productIdentifry

           appDelegate.showHud()

           Task {
               await IAPManager.shared.purchase(productId: productID)
           }
        
//        if self.selectedIndex == 99 {
//            popupAlert(title: "Select Plan", message: "Please select a subscription plan first.", actionTitles: ["OK"], actions: [{ _ in }, nil])
//            return
//        }
//
//        if self.iapProducts.count > 0{
//            let productID1 =  (self.isMonthlySelected) ? self.arrSubsDataMonthly[self.selectedIndex].productIdentifry : self.arrSubsDataYearly[self.selectedIndex].productIdentifry
//            appDelegate.showHud()
//            self.setProductPurchase(strProductId: productID1)
//        }else
//        {
//            self.popupAlert(
//                title: "Error",
//                message: "Something went wrong. Please try again later.",
//                actionTitles: ["OK"],
//                actions: [{ action1 in
//                }, nil]
//            )
//        }
    }
    @IBAction func tapToRestore(_ sender: UIButton) {
        isConnectedToNetwork1 { isConnected in
                if isConnected {
                    appDelegate.showHud()
                    Task {
                        await IAPManager.shared.restorePurchases()
                    }
                }
            }
    }
    @IBAction func tapToMonthly(_ sender: UIButton) {
        if !self.isMonthlySelected
        {
            self.setupMonthYearSegmentSelectionWith(isMonth: true, aSelectedBtn: self.btnMonthly, aNoSelectBtn: self.btnYearly)
        }
    }
    @IBAction func tapToYearly(_ sender: UIButton) {
        if self.isMonthlySelected
        {
            self.setupMonthYearSegmentSelectionWith(isMonth: false, aSelectedBtn: self.btnYearly, aNoSelectBtn: self.btnMonthly)
        }
    }
    @IBAction func tapToCloseInfoPage(_ sender: UIButton) {
        self.viewForPaymentDetails.isHidden = true
    }
    @IBAction func tapToTermsAndPolicy(_ sender: UIControl) {
        let objWebViewCommonVC = self.storyboard?.instantiateViewController(withIdentifier:"WebViewCommonVC" ) as! WebViewCommonVC
        objWebViewCommonVC.strTitle = "Terms and Policy"
        self.navigationController?.pushViewController(objWebViewCommonVC, animated: true)
    }
    
    func setupMonthYearSegmentSelectionWith(isMonth:Bool,aSelectedBtn:UIButton,aNoSelectBtn:UIButton)
    {
        self.selectedIndex = 99
        self.isMonthlySelected = isMonth
        aSelectedBtn.setTitleColor(UIColor.white, for: .normal)
        aSelectedBtn.backgroundColor = UIColor.init(named:"AppDarkBlue")!
        aNoSelectBtn.backgroundColor = UIColor.white
        aNoSelectBtn.setTitleColor(UIColor.init(named:"AppDarkBlue")!, for: .normal)
        self.collViewPlanList.reloadData()
    }
}

//MARK: - In-app Purcahse Delegates....
//extension SubscriptionListVC: SKProductsRequestDelegate,SKPaymentTransactionObserver,SKRequestDelegate
//{
//    // MARK: - FETCH AVAILABLE IAP PRODUCTS
//    func fetchAvailableProducts()  {
//
//        appDelegate.showHud(isWhiteBG: true)
//        // Put here your IAP Products ID's
//        let productIdentifiers = NSSet(objects:
//          oneChild_1Month,twoChild_1Month,threeChild_1Month,fourChild_1Month,oneChild_Yearly,twoChild_Yearly,threeChild_Yearly,fourChild_Yearly
//        )
//        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
//        productsRequest.delegate = self
//        productsRequest.start()
//    }
   
//    //MARK: - REQUEST IAP PRODUCTS
//    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
//
//        print("Valid products count:", response.products.count)
//        print("Invalid products:", response.invalidProductIdentifiers)
//
//        if (response.products.count > 0) {
//            iapProducts = response.products
//            print(iapProducts)
//
////            let numberFormatter = NumberFormatter()
////            numberFormatter.formatterBehavior = .behavior10_4
////            numberFormatter.numberStyle = .currency
////
////            for productDetails in iapProducts
////            {
////                //let productDetails = iapProducts[i]
////                // Get its price from iTunes Connect
////                numberFormatter.locale = productDetails.priceLocale
////                let productPrice = numberFormatter.string(from: productDetails.price)
////                let productTitle = productDetails.localizedTitle
////                let productModel = SubscriptionModel()
////                productModel.name = productTitle
////                productModel.price = productPrice!
////                productModel.productIdentifry = productDetails.productIdentifier
////                let allowedCharset = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ""))
////                let filteredText = String(productPrice!.unicodeScalars.filter(allowedCharset.contains))
////                productModel.sortPrice = Int(filteredText)!
////                arrSubscriptionData.append(productModel)
////            }
////
////            self.collViewPlanList.reloadData()
//        }
//        appDelegate.hideHud()
//    }
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//
//        for trans in transactions {
//
//
//            guard let transactionId = trans.transactionIdentifier ??
//                                      trans.original?.transactionIdentifier else {
//                SKPaymentQueue.default().finishTransaction(trans)
//                continue
//            }
//
//            if handledTransactionIDs.contains(transactionId) {
//                SKPaymentQueue.default().finishTransaction(trans)
//                continue
//            }
//
//            switch trans.transactionState {
//
//            case .purchased:
//                handledTransactionIDs.insert(transactionId)
//
//                print("✅ Purchased:", transactionId)
//                let productId = trans.original?.payment.productIdentifier ?? trans.payment.productIdentifier
//
//                // 👉 your success logic
//                var childCount = ""
//                if isMonthlySelected
//                {
//                    childCount = arrSubsDataMonthly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                }else {
//                    childCount = arrSubsDataYearly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                }
//               self.apiCallForSubscription(aTransactionID: transactionId, aChildCount: childCount, aBunddleID: productId)
//
//                SKPaymentQueue.default().finishTransaction(trans)
//                appDelegate.hideHud()
//
//            case .restored:
//                handledTransactionIDs.insert(transactionId)
//
//                let productId = trans.original?.payment.productIdentifier ?? trans.payment.productIdentifier
//                print("♻️ Restored:", transactionId, productId)
//
//                // 👉 your restore logic
//                var childCount = ""
//                if isMonthlySelected
//                {
//                    childCount = arrSubsDataMonthly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                }else {
//                    childCount = arrSubsDataYearly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                }
//               self.apiCallForSubscription(aTransactionID: transactionId, aChildCount: childCount, aBunddleID: productId)
//                SKPaymentQueue.default().finishTransaction(trans)
//                appDelegate.hideHud()
//
//            case .failed:
//                if let error = trans.error as? SKError,
//                   error.code != .paymentCancelled {
//                    print("❌ Error:", error.localizedDescription)
//                }
//
//                SKPaymentQueue.default().finishTransaction(trans)
//                appDelegate.hideHud()
//
//            case .purchasing:
//                break
//
//            case .deferred:
//                appDelegate.hideHud()
//
//            @unknown default:
//                break
//            }
//        }
//    }
//    // MARK: - IAP PAYMENT QUEUE
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//
//        //IJProgressView.shared.showProgressView(view)
//        for transaction:AnyObject in transactions {
//            if let trans = transaction as? SKPaymentTransaction {
//
//                switch trans.transactionState {
//                case .purchasing:
//                          break
//                case .purchased:
//                    //Get data from backend and set user free..
////                    self.getDataOfPurchaseFromApi()
////                    let transactionId = transaction.transactionIdentifier ?? ""
////                    let productId = transaction.payment.productIdentifier
//                    let transactionId = trans.transactionIdentifier ?? ""
//                    let productId = trans.payment.productIdentifier
//                    print("STATE:", trans.transactionState.rawValue)
//                    print("PRODUCT:", trans.payment.productIdentifier)
//                    print("transactionid_\(transactionId) and productid_\(productId)")
//                    var childCount = ""
//                    if isMonthlySelected
//                    {
//                        childCount = arrSubsDataMonthly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                    }else {
//                        childCount = arrSubsDataYearly.first(where: {$0.productIdentifry == productId})?.childCount ?? ""
//                    }
//                   self.apiCallForSubscription(aTransactionID: transactionId, aChildCount: childCount, aBunddleID: productId)
//                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    appDelegate.hideHud()
//                    break
//                case .failed:
//                    appDelegate.hideHud()
////                    self.popupAlert(
////                        title: "Purchase Failed",
////                        message: "The in-app purchase could not be completed. Please try again.",
////                        actionTitles: ["OK"],
////                        actions: [{ action1 in
////                        }, nil]
////                    )
//                    if let error = trans.error as? SKError {
//                            print("Purchase error:", error.code, error.localizedDescription)
//                        }
//                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    break
//                case .restored:
//                    //Get data from backend and set user free..
//                    let transactionId = transaction.original?.transactionIdentifier ?? ""
//                    let productId = transaction.original?.payment.productIdentifier ?? transaction.payment.productIdentifier
//                    print("transactionid_\(transactionId) and productid_\(productId)")
//
//                    // send transactionId & productId to backend if needed
//                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
//                    appDelegate.hideHud()
//                    break
//                default: break
//                }}}
//    }
//
//    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue)    {
//        for transact:SKPaymentTransaction in queue.transactions        {
//
//            if transact.transactionState == SKPaymentTransactionState.restored
//            {
//                SKPaymentQueue.default().finishTransaction(transact)
//            }
//            if transact.transactionState == SKPaymentTransactionState.purchased
//            {
//                SKPaymentQueue.default().finishTransaction(transact)
//            }
//        }
//    }
//
//    // MARK: - MAKE PURCHASE OF A PRODUCT
//    func canMakePurchases() -> Bool {
//        print(SKPaymentQueue.canMakePayments())
//        return SKPaymentQueue.canMakePayments()
//    }
//    func purchaseMyProduct(product: SKProduct) {
//
//        if self.canMakePurchases() {
//            print(SKPaymentQueue.canMakePayments())
//            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
//            self.productID = product.productIdentifier
//            let payment = SKPayment(product: product)
//            SKPaymentQueue.default().add(payment)
//            SKPaymentQueue.default().add(self)
//        } else {
//            appDelegate.hideHud()
//            //            self.view.makeToast("تم تعطيل المشتريات في جهازك!")
//            self.popupAlert(title: "", message: "Purchases have been disabled on your device!", actionTitles: ["OK"], actions:[{action1 in
//            }, nil])
//        }
//    }
//    func request(_ request: SKRequest, didFailWithError error: Error) {
//        print("app receipt refresh request did fail with error: \(error)")
//        // for some clues see here: https://samritchie.net/2015/01/29/the-operation-couldnt-be-completed-sserrordomain-error-100/
//    }
//
//    //MARK: - Set action on purchase product..
//    func setProductPurchase(strProductId : String)
//    {
//        isConnectedToNetwork1 { [self] isConnected in
//            if isConnected {
//                for productMain in iapProducts
//                {
//                    if productMain.productIdentifier == strProductId{
//                        purchaseMyProduct(product: productMain)
//                        return
//                    }
//                }
//            }
//        }
//    }
//}

//MARK: - Collectionview delegates and datasource...
extension SubscriptionListVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let spacing: CGFloat = 3
        let totalSpacing = spacing * 1 // 3 cells = 2 spaces
        let width = (collViewPlanList.bounds.width - totalSpacing) / 2

        return CGSize(width: floor(width), height: 165)
    }
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
          return 3
      }

      func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          minimumLineSpacingForSectionAt section: Int) -> CGFloat {
          return 3
      }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isMonthlySelected
        {
            return self.arrSubsDataMonthly.count
        }
        return self.arrSubsDataYearly.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellForPlans", for: indexPath) as! CellForPlans
        cell.setupCellDataFromModelDataWith(dataModel:(self.isMonthlySelected) ? self.arrSubsDataMonthly[indexPath.row] : self.arrSubsDataYearly[indexPath.row],selectedIndex:self.selectedIndex,currentIndex:indexPath.row)
        return cell

    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.collViewPlanList.reloadData()
    }
}

//MARK: - Api callings...
extension SubscriptionListVC
{
    //MARK: - Subscribed api...
    func apiCallForSubscription(aTransactionID:String,aChildCount:String,aBunddleID:String)
    {
        let param = ["originalTransactionId":aTransactionID,"maxChild":aChildCount,"bundleId":"org.app.GaurdianDrive"] as [String : Any]
        
        print(param)
        
        apiCallViewModel.postApiCallWithDisctionaryResponse(aUrl: WebURL.subscriptionVerify, param:param) { (isSuccess, responseDict,statusCode)  in
            
            appDelegate.hideHud()
            
            if isSuccess
            {
                print(responseDict)
                
                let dict = responseDict as NSDictionary

                // ✅ Map to model
                let userSubscriptionData = UserSubscriptionResponseModel.init(dict: dict)
                let status = getSubscriptionStatus(userSubscriptionData.expiresDateLocal)

                switch status {

                case .expired:
                    appDelegate.isPurchaseVIP = false
                    appDelegate.subscriptionExpireDate = "Subscription Expired"
                    self.popupAlert(
                        title: "Subscription not purchased",
                        message: "Please purchase the subscription to continue using the app.",
                        actionTitles: ["OK"],
                        actions: [{ _ in
                            // Optional: redirect to purchase screen
                        }, nil]
                    )

                case .active(let message):

                    appDelegate.subscriptionExpireDate = message
                    appDelegate.isPurchaseVIP = true
                    print("✅ Active:", message)
                    self.popupAlert(
                        title: "Subscription Successful",
                        message: "Your subscription has been activated successfully.",
                        actionTitles: ["OK"],
                        actions: [{ _ in
                            self.navigationController?.popViewController(animated: true)
                        }, nil]
                    )
                }
                //UI update
                self.selectedIndex = 99
                self.collViewPlanList.reloadData()
            }
        }
    }
}
