//
//  IntroVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 11/12/25.
//

import UIKit

// MARK: - Slide Data Model
struct IntroSlide {
    let imageName: String
    let title1: String
    let title2: String
    let description: String
}

class IntroVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet var collViewList: UICollectionView!
    @IBOutlet var pageControl: UIPageControl!

    // MARK: - Data
    let slides: [IntroSlide] = [
        IntroSlide(
            imageName: "Img_Intro",
            title1: "Smart Safety",
            title2: "Starts with You",
            description: "GuardianDrive helps you stay in control and keep your family safe on every journey."
        ),
        IntroSlide(
            imageName: "Img_Intro",
            title1: "Monitor Speed",
            title2: "In Real Time",
            description: "Get instant alerts when speed limits are exceeded so you can act before it's too late."
        ),
        IntroSlide(
            imageName: "Img_Intro",
            title1: "Block Distractions",
            title2: "While Driving",
            description: "Automatically restrict apps when the vehicle is in motion, keeping focus on the road."
        ),
        IntroSlide(
            imageName: "Img_Intro",
            title1: "Stay Connected",
            title2: "Stay Protected",
            description: "Track location, set schedules, and receive notifications — all from one place."
        )
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialisation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.setHidesBackButton(true, animated: true)
    }
}

// MARK: - Initialisation
extension IntroVC {

    func initialisation() {
        UserDefaults.Main.set(true, forKey: .isInfoDone)
        self.collViewList.register(UINib(nibName: "CellForIntro", bundle: nil), forCellWithReuseIdentifier: "CellForIntro")
        self.pageControl.numberOfPages = slides.count
        self.pageControl.currentPage = 0
    }
}

// MARK: - Button Actions
extension IntroVC {

    @IBAction func tapToSkip(_ sender: UIButton) {
        let objChooseRoleVC = storyBoards.Main.instantiateViewController(withIdentifier: "ChooseRoleVC") as! ChooseRoleVC
        self.navigationController?.pushViewController(objChooseRoleVC, animated: true)
    }

    @IBAction func tapToNext(_ sender: UIButton) {
        let currentPage = pageControl.currentPage
        if currentPage < slides.count - 1 {
            // Scroll to next slide
            let nextIndex = IndexPath(item: currentPage + 1, section: 0)
            collViewList.scrollToItem(at: nextIndex, at: .centeredHorizontally, animated: true)
            pageControl.currentPage = currentPage + 1
        } else {
            // Last slide — go to ChooseRole
            let objChooseRoleVC = storyBoards.Main.instantiateViewController(withIdentifier: "ChooseRoleVC") as! ChooseRoleVC
            self.navigationController?.pushViewController(objChooseRoleVC, animated: true)
        }
    }
}

// MARK: - CollectionView
extension IntroVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ScreenSize.width, height: ScreenSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellForIntro", for: indexPath) as! CellForIntro
        let slide = slides[indexPath.row]
        cell.imgInfos.image = UIImage(named: slide.imageName)
        cell.lblTitle1.text = slide.title1
        cell.lblTitle2.text = slide.title2
        cell.lblDesc.text = slide.description
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / ScreenSize.width))
        pageControl.currentPage = page
    }
}
