//
//  ParentControlPasscodeVC.swift
//  GaurdianDrive
//
//  Created by Antigravity on 02/02/26.
//

import SwiftData
import SwiftUI
import UIKit

class ParentControlPasscodeVC: UIViewController {

    // MARK: - Properties
    var onSuccess: (() -> Void)?
    var strCustomTitle: String?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = self.strCustomTitle ?? "Enter passcode to proceed child configuration"
        lbl.font = UIFont(name: "PlusJakartaSans-Bold", size: 24)
        lbl.textColor = UIColor(named: "AppDarkBlue") ?? .black
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var noteLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Note: if you dont remember passcode please reset from parent app"
        lbl.font = UIFont(name: "PlusJakartaSans-Medium", size: 15)
        lbl.textColor = UIColor(named: "PlaceholderGray") ?? .gray
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var passcodeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var digitTextFields: [OTPTextField] = []

    private lazy var proceedButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Proceed", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(named: "AppDarkBlue")
        btn.layer.cornerRadius = 8
        btn.titleLabel?.font = UIFont(name: "PlusJakartaSans-SemiBold", size: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tapToProceed), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        setupUI()
        setupPasscodeFields()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        // Focus first field
        digitTextFields.first?.becomeFirstResponder()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(noteLabel)
        view.addSubview(passcodeStackView)
        view.addSubview(proceedButton)

        // Add SwiftUI Header
        let headerView = BackHeaderView { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        let hostingController = UIHostingController(rootView: headerView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        NSLayoutConstraint.activate([
            // Header Constraints
            hostingController.view.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 60),  // Approx height covering padding + button

            // Title - anchor to header bottom
            titleLabel.topAnchor.constraint(
                equalTo: hostingController.view.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Note
            noteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            noteLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noteLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Stack View
            passcodeStackView.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 40),
            passcodeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            passcodeStackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -30),
            passcodeStackView.heightAnchor.constraint(equalToConstant: 50),

            // Proceed Button
            proceedButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            proceedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            proceedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            proceedButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func setupPasscodeFields() {
        for i in 0..<4 {
            let tf = OTPTextField()
            tf.backgroundColor = .clear
            tf.layer.borderWidth = 1
            tf.layer.borderColor =
                UIColor(named: "AppBorderGray")?.cgColor ?? UIColor.lightGray.cgColor
            tf.layer.cornerRadius = 8
            tf.textAlignment = .center
            tf.font = UIFont(name: "PlusJakartaSans-Bold", size: 24)
            tf.keyboardType = .numberPad
            tf.textColor = UIColor(named: "AppDarkBlue")
            tf.tag = i
            tf.delegate = self

            // Add target for text change
            tf.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

            passcodeStackView.addArrangedSubview(tf)
            digitTextFields.append(tf)
        }
        // Wire backward navigation
        for i in 1..<digitTextFields.count {
            digitTextFields[i].previousTextField = digitTextFields[i - 1]
        }
    }

    // MARK: - Actions
    // MARK: - Actions

    @objc func tapToProceed() {
        let code = digitTextFields.map { $0.text ?? "" }.joined()
        print("Passcode entered: \(code)")
        if code.count == 4 {
            // Check if passcode is correct

            apiCallForVerifyPinCode(aPinText: code)

        } else {
            let alert = UIAlertController(
                title: "Error", message: "Please enter a 4-digit passcode", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc func textDidChange(_ textField: UITextField) {
        let text = textField.text

        if (text?.count ?? 0) >= 1 {
            let index = textField.tag
            if index < 3 {
                digitTextFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }
}

extension ParentControlPasscodeVC: UITextFieldDelegate {
    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Allow only digits
        if !string.isEmpty
            && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
        {
            return false
        }

        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)

        // Paste: take only the first character
        if newText.count > 1 {
            textField.text = String(newText.prefix(1))
            self.textDidChange(textField)
            return false
        }
        return true
    }
}

//MARK: - Api calling methods...
extension ParentControlPasscodeVC{
    
    func apiCallForVerifyPinCode(aPinText:String)
    {
        let param = ["pin":aPinText] as [String : Any]

        appDelegate.getPasscodeApprovedApi(url:WebURL.getPinVerify, params: param) { (isSuccess, responseDict, statusCode) in

            if isSuccess {
                if let onSuccess = self.onSuccess {
                    self.navigationController?.popViewController(animated: true)
                    onSuccess()
                    return
                }

                // Reuse the ModelContainer already created by AppDelegate.checkLogin().
                // Creating a second ModelContainer for the same on-disk store causes
                // SwiftData crashes ("store already open"). Only create one as a fallback.
                AppBlockerManager.shared.ensureModelContainer()
                guard let container = AppBlockerManager.shared.modelContainer else {
                    let alert = UIAlertController(
                        title: "Error", message: "Database unavailable. Please restart the app.",
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    return
                }

                // Re-wire the shared ViewModel's context in case it was cleared (e.g. after logout).
                Task { @MainActor in
                    ParentControlViewModel.shared.setModelContext(container.mainContext)
                }

                let parentControlView = ParentControlView(onBack: { [weak self] in
                    guard let self = self, let navController = self.navigationController else { return }
                    if let profileVC = navController.viewControllers.first(where: { $0 is ProfileVC }) {
                        navController.popToViewController(profileVC, animated: true)
                    } else {
                        navController.popViewController(animated: true)
                    }
                })
                .modelContainer(container)

                let hostingController = UIHostingController(rootView: parentControlView)
                hostingController.navigationItem.hidesBackButton = true
                self.navigationController?.pushViewController(hostingController, animated: true)
            } else {
                var strMessage = getStringFromDictionary(dictionary: responseDict, key: "defaultMessage")
                if strMessage == ""
                {
                    strMessage = "The passcode you entered is incorrect"
                }
                appDelegate.window?.rootViewController?.view.makeToast(strMessage)
            }
        }
    }
}
