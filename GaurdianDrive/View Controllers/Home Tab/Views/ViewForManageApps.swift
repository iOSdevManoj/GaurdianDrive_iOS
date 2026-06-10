//
//  ViewForManageApps.swift
//  GaurdianDrive
//
//  Created by KETAN on 26/12/25.
//

import UIKit



class ViewForManageApps: UIView {
    
    //Outlets....
    @IBOutlet var collViewApprovedList: UICollectionView!
    @IBOutlet var collViewOtherList: UICollectionView!
    @IBOutlet weak var contentView: UIView! // main white card

    //Variables...
    var approvedApps: [ChildRequestedApp] = []
    var otherApps: [ChildRequestedApp] = []
    
    //Call backs..
    var onClose: (() -> Void)?
    var onUpdate: (([ChildRequestedApp]) -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let nib = UINib(nibName: "CellForAppsList", bundle: nil)

        collViewApprovedList.register(nib, forCellWithReuseIdentifier: "CellForAppsList")
        collViewOtherList.register(nib, forCellWithReuseIdentifier: "CellForAppsList")

        collViewApprovedList.delegate = self
        collViewApprovedList.dataSource = self
        
        collViewOtherList.delegate = self
        collViewOtherList.dataSource = self
    }
}

//MARK: - Click events..
extension ViewForManageApps{
    @IBAction func tapToCloseView(_ sender: UIButton) {
        closeAnimated {
            self.onClose?()
        }
    }
    @IBAction func tapToUpdate(_ sender: UIButton) {
        closeAnimated { [self] in
            onUpdate?(approvedApps)
        }
    }
}

//MARK: - Collectionview delegates and datasource...
extension ViewForManageApps : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 110, height: 110)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == collViewApprovedList
        ? approvedApps.count
        : otherApps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "CellForAppsList",
            for: indexPath
        ) as! CellForAppsList
        
        if collectionView == collViewApprovedList {
            
            let app = approvedApps[indexPath.item]
            cell.configure(app: app, isApproved: true, isFromChild: false)
            
            cell.onActionTap = { [weak self] in
                guard let self else { return }
                
                let removedApp = self.approvedApps.remove(at: indexPath.item)
                self.otherApps.append(removedApp)
                
                self.reloadCollections()
            }
            
        } else {
            
            let app = otherApps[indexPath.item]
            cell.configure(app: app, isApproved: false, isFromChild: false)
            
            cell.onActionTap = { [weak self] in
                guard let self else { return }
                
                let addedApp = self.otherApps.remove(at: indexPath.item)
                self.approvedApps.append(addedApp)
                
                self.reloadCollections()
            }
        }
        
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
    private func reloadCollections() {
        collViewApprovedList.reloadData()
        collViewOtherList.reloadData()
    }
}

//MARK: -  Open and close animation funcions..
extension ViewForManageApps{
    func openAnimated() {
        
        layoutIfNeeded()
        
        self.alpha = 0
        contentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut]
        ) {
            self.alpha = 1
            self.contentView.transform = .identity
        }
    }
    
    func closeAnimated(completion: (() -> Void)? = nil) {

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            self.alpha = 0
            self.contentView.transform = CGAffineTransform(
                translationX: 0,
                y: UIScreen.main.bounds.height
            )
        } completion: { _ in
            completion?()
        }
    }
}
