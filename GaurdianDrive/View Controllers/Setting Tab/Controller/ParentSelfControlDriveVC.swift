//
//  ParentSelfConrollDriveVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 24/03/26.
//

import UIKit
import SwiftData
import SwiftUI
import FamilyControls
import ManagedSettings

class ParentSelfControlDriveVC: UIViewController {

    //Outlets.
    @IBOutlet var lblCurrenSpeed: UILabel!
    @IBOutlet var collViewApprovedAppsList: UICollectionView!
    @IBOutlet var lblDriveModeOn: UILabel!

    // Variables
    var blockedApps: [ChildRequestedApp] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initilaisation()
        // Init SwiftData once so AppBlockerManager + ParentControlViewModel
        // share the same ModelContainer throughout this session.
        setupSwiftDataAndLoadApps()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil {
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(speedUpdated(_:)), name: .speedDidUpdate, object: nil)
        let currentSpeed = LocationPermissionManager.shared.getSpeedMPH()
        updateSpeedUI(speedMPH: currentSpeed)
        // Reload the list every time we appear — picks up changes made in ParentControlView.
        loadBlockedApps()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .speedDidUpdate, object: nil)
    }

    @objc private func speedUpdated(_ notification: Notification) {
        let currentSpeed = LocationPermissionManager.shared.getSpeedMPH()
        updateSpeedUI(speedMPH: currentSpeed)
    }

    private func updateSpeedUI(speedMPH: Double) {
        DispatchQueue.main.async {
            self.lblCurrenSpeed.text = String(format: "%.0f MPH", speedMPH)
            self.lblDriveModeOn.isHidden = speedMPH <= AppBlockerManager.shared.parentsSpeedLimitMph
        }
    }

    private func setupSwiftDataAndLoadApps() {
        // Reuse the container already created by AppDelegate.checkLogin().
        // Creating a second ModelContainer for the same store causes crashes.
        if AppBlockerManager.shared.modelContainer == nil {
            do {
                let schema = Schema([BlockingSelection.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [config])
                AppBlockerManager.shared.modelContainer = container
                ParentControlViewModel.shared.setModelContext(container.mainContext)
            } catch {
                print("Failed to initialize SwiftData: \(error)")
            }
        }
        loadBlockedApps()
    }

    private func loadBlockedApps() {
        // Ensure SwiftData is loaded before reading from the ViewModel
        Task { @MainActor in
            await ParentControlViewModel.shared.loadDataIfNeeded()
            let ownTokens = ParentControlViewModel.shared.ownAppTokens
            let selectedTokens = ParentControlViewModel.shared.selection.applicationTokens
            let statuses = ParentControlViewModel.shared.appStatuses

            self.blockedApps = selectedTokens
                .filter { !ownTokens.contains($0) }
                .filter { token in
                    return statuses.first(where: { $0.token == token })?.isBlocked == true
                }
                .compactMap { token -> ChildRequestedApp? in
                    let name = statuses.first(where: { $0.token == token })?.appName
                    var base64Token: String? = nil
                    if let data = try? JSONEncoder().encode(token) {
                        base64Token = data.base64EncodedString()
                    }
                    return ChildRequestedApp(appName: name, token: base64Token)
                }
            self.collViewApprovedAppsList.reloadData()
        }
    }
}

//MARK: - Initialisations..
extension ParentSelfControlDriveVC
{
    func initilaisation()
    {
        self.lblDriveModeOn.isHidden = true // This will be shown while speed is above 15 mph
        self.collViewApprovedAppsList.register(
            UINib(nibName: "CellForAppsList", bundle: nil),
            forCellWithReuseIdentifier: "CellForAppsList")

    }
}

//MARK: - Action events -
extension ParentSelfControlDriveVC {
    @IBAction private func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction private func tapToAddApproveApps(_ sender: UIControl) {
        guard let container = AppBlockerManager.shared.modelContainer else { return }
        
        let parentControlView = ParentControlView(onBack: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
        .modelContainer(container)

        let hostingController = UIHostingController(rootView: parentControlView)
        hostingController.navigationItem.hidesBackButton = true
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
}

//MARK: - Collectionview delegates and datasource...
extension ParentSelfControlDriveVC: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return blockedApps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "CellForAppsList", for: indexPath) as! CellForAppsList
        cell.btnDeleteAdd.isHidden = true
        let app = blockedApps[indexPath.row]
        cell.configure(app: app, isApproved: true, isFromChild: false)
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 10
    }
}
