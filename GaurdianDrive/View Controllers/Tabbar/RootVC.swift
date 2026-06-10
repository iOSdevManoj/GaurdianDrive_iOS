//
//  RootVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 15/12/25.
//

import UIKit

enum TabType :Int{
    case HomeTab = 1
    case ReportTab
    case SettingTab
}
var rootTab = RootVC()

class RootVC: UIViewController {
    
    @IBOutlet var imgsTab: [UIImageView]!
    @IBOutlet var cntrlsTab: [UIControl]!
    @IBOutlet weak var viewBottomTabMain: UIView!
    @IBOutlet weak var viewContentView: UIView!
    @IBOutlet weak var consCenterLblSlider: NSLayoutConstraint!
    @IBOutlet weak var cons_bottomBar_height: NSLayoutConstraint!
    @IBOutlet weak var consLblSliderWidth: NSLayoutConstraint!

    let tabVC = storyBoards.Tabbar.instantiateViewController(withIdentifier: "TabBarVC") as? TabBarVC
    
    let arrEnumTabs = [TabType.HomeTab,TabType.ReportTab,TabType.SettingTab]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rootTab  = self
        self.showBottomTab()
        self.setTabSelected(.HomeTab)
        self.view.bringSubviewToFront(self.viewBottomTabMain)
        
        tabVC?.tabBar.isHidden = false
        self.viewBottomTabMain.backgroundColor = UIColor.init(named: "AppDarkBlue")

    }
}

extension RootVC {
    
    func showBottomTab(){
        self.tabVC!.willMove(toParent: self)
        self.tabVC!.view.frame = CGRect(x: 0, y: 0, width: viewContentView.frame.size.width, height: viewContentView.frame.size.height)
        viewContentView.addSubview(self.tabVC!.view)
        self.addChild(self.tabVC!)
        self.tabVC!.didMove(toParent: self)
        self.tabVC!.view.backgroundColor = UIColor.clear
    }
    
    //Set selected tab
    func setTabSelected(_ selectedTab : TabType) {
        
//        tabVC?.tabBar.isHidden = false
//        self.viewBottomTabMain.backgroundColor = UIColor.init(named: "AppDarkBlue")

        for cntrl in self.cntrlsTab{
            if cntrl.tag == selectedTab.rawValue {
                //let originX = (cntrl.frame.origin.x)
                //let halfWidth = (cntrl.frame.size.width / 2)
                DispatchQueue.main.async {
                    let centerX = (cntrl.center.x)

                    //let x = cntrl.center.x//((cntrl.frame.origin.x) + ((cntrl.frame.size.width ?? 0) / 2))
                    self.consCenterLblSlider.constant = centerX //originX + halfWidth
                    self.consLblSliderWidth.constant = ScreenSize.width / 3
                    self.view.layoutIfNeeded()
                }
            }
        }

        if selectedTab == .HomeTab{
            self.setupTabsSelectionImages(aTabImg1: "tab_home_white", aTabImg2: "tab_report_light", aTabImg3: "tab_setting_light")
        }
        else if selectedTab == .ReportTab{
            self.setupTabsSelectionImages(aTabImg1: "tab_home_light", aTabImg2: "tab_report_white", aTabImg3: "tab_setting_light")
        }
        else if selectedTab == .SettingTab{
            self.setupTabsSelectionImages(aTabImg1: "tab_home_light", aTabImg2: "tab_report_light", aTabImg3: "tab_setting_white")
        }

        let selectedTab = selectedTab.rawValue - 1
        if selectedTab >= 0
        {
            tabVC?.selectedIndex  = selectedTab
            self.tabBarController?.selectedIndex = selectedTab
        }else{
            tabVC?.selectedIndex  = 0
            self.tabBarController?.selectedIndex = 0
        }
        self.view.layoutIfNeeded()
    }
    
    func setupTabsSelectionImages(aTabImg1:String,aTabImg2:String,aTabImg3:String)
    {
        self.imgsTab[0].image = UIImage(named:aTabImg1)
        self.imgsTab[1].image = UIImage(named:aTabImg2)
        self.imgsTab[2].image = UIImage(named:aTabImg3)
    }
    
}

//Action Events
extension RootVC {
    @IBAction func clickOnTabs(_ sender: UIControl) {
        let indexReal = sender.tag - 1
        if indexReal >= 0
        {
            self.setTabSelected(self.arrEnumTabs[indexReal])
        }
    }
}

extension RootVC {
    func isTabShow(aHide:Bool){
        self.tabVC?.tabBar.isHidden = aHide
        self.tabVC?.tabBar.isTranslucent = true
    }
}
