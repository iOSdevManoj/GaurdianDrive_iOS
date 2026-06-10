//
//  ViewForReqAppSelection.swift
//  GaurdianDrive
//
//  Created by KETAN on 24/12/25.
//

import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

// MARK: - Combined row label style (icon 28×28 + title)

private struct AppSelectionRowStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            configuration.title
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(UIColor.label))
                .lineLimit(1)
        }
    }
}

class ViewForReqAppSelection: UIView {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var viewforTextfields: UIView!
    @IBOutlet weak var txtfield1: UITextField!
    @IBOutlet weak var txtfield2: UITextField!
    @IBOutlet weak var cons_textfield2_height: NSLayoutConstraint!
    @IBOutlet weak var viewforTableList: UIView!
    @IBOutlet weak var lblListTitle: UILabel!
    @IBOutlet weak var tblViewLists: UITableView!

    // MARK: - Data
    private var dropdownItems: [String] = []
    private var appTokenItems: [ApplicationToken] = []
    private var appTokenNames: [String] = []
    private var tokenStringMap: [Int: String] = [:]
    private var isTokenMode: Bool = false
    private var activeTextField: UITextField?
    private var selectedIndex: Int?
    /// Locally-resolved names from Label(token) rendering — overrides server-stored names at submit time
    private var locallyResolvedNames: [Int: String] = [:]

    // MARK: - Submitted apps stack (one permanent card per submission, no reuse)
    private var submittedStackView: UIStackView?

    // MARK: - State views
    private var emptyLabel: UILabel?
    private var loadingIndicator: UIActivityIndicatorView?

    /// Number of tokens whose names are still being resolved by FamilyControlsAgent.
    /// The Submit button is disabled until this reaches 0.
    private var pendingResolutionCount: Int = 0

    /// SwiftUI hosting controller overlaid on txtfield1 to show the real app name
    private var selectedNameHC: UIHostingController<AnyView>?

    // MARK: - Callbacks
    var onSelect: ((Int, String) -> Void)?
    var onSubmit: ((_ first: String, _ second: String?, _ appName: String?) -> Void)?
    var onCloseView: (() -> Void)?
    private var firstValue: String?
    private var secondValue: String?
    /// Tracks whether the selected item is a category ("category") or app ("app")
    private(set) var selectedType: String = "app"

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.endEditing(true)
    }

    // MARK: - XIB Initialisation
    static func loadXib() -> ViewForReqAppSelection {
        let nib = UINib(nibName: "ViewForReqAppSelection", bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! ViewForReqAppSelection
    }
    // MARK: - Append a newly submitted app card to the stack
    func appendSubmittedApp(tokenString: String, appName: String) {
        ensureSubmittedStackExists()
        guard let stack = submittedStackView else { return }

        // ── Card ────────────────────────────────────────────────────────────
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(named: "AppBorderGray")?.cgColor
            ?? UIColor.separator.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 80).isActive = true

        // ── App icon ─────────────────────────────────────────────────────────
        // Pure UIKit letter avatar — zero SwiftUI, zero cross-contamination.
        // appName is already fully resolved before this is called, so no token
        // lookup is needed and SwiftUI never touches these cards again.
        let iconSize: CGFloat = 44
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 10
        iconContainer.clipsToBounds = true
        iconContainer.backgroundColor = UIColor(named: "AppDarkBlue") ?? .systemBlue
        card.addSubview(iconContainer)

        let letter = UILabel()
        letter.text = String(appName.prefix(1)).uppercased()
        letter.font = .systemFont(ofSize: 20, weight: .semibold)
        letter.textColor = .white
        letter.textAlignment = .center
        letter.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(letter)
        NSLayoutConstraint.activate([
            letter.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            letter.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            letter.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            letter.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
        ])

        // ── App name — plain UILabel with the already-resolved string ────────
        let nameLbl = UILabel()
        nameLbl.text = appName          // already resolved — no SwiftUI lookup needed
        nameLbl.font = .systemFont(ofSize: 15, weight: .medium)
        nameLbl.textColor = .label
        nameLbl.translatesAutoresizingMaskIntoConstraints = false

        // ── Timestamp ────────────────────────────────────────────────────────
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        let timeLbl = UILabel()
        timeLbl.text = fmt.string(from: Date())
        timeLbl.font = .systemFont(ofSize: 12)
        timeLbl.textColor = .secondaryLabel
        timeLbl.translatesAutoresizingMaskIntoConstraints = false

        // ── REQUESTED badge ──────────────────────────────────────────────────
        let badge = UILabel()
        badge.text = "REQUESTED"
        badge.font = .systemFont(ofSize: 11, weight: .semibold)
        badge.textColor = UIColor(named: "AppFontBlue") ?? .systemBlue
        badge.backgroundColor = (UIColor(named: "AppFontBlue") ?? .systemBlue).withAlphaComponent(0.10)
        badge.layer.cornerRadius = 5
        badge.layer.masksToBounds = true
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconContainer)
        card.addSubview(nameLbl)
        card.addSubview(timeLbl)
        card.addSubview(badge)

        NSLayoutConstraint.activate([
            // Icon
            iconContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: iconSize),
            iconContainer.heightAnchor.constraint(equalToConstant: iconSize),

            // Badge — top-right
            badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            badge.widthAnchor.constraint(equalToConstant: 82),
            badge.heightAnchor.constraint(equalToConstant: 20),

            // Name — left of badge, right of icon
            nameLbl.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 10),
            nameLbl.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -8),
            nameLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            // Time — below name
            timeLbl.leadingAnchor.constraint(equalTo: nameLbl.leadingAnchor),
            timeLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 4),
            timeLbl.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -12),
        ])

        stack.addArrangedSubview(card)
        UIView.animate(withDuration: 0.25) { stack.superview?.layoutIfNeeded() }
    }

//    private func ensureSubmittedStackExists() {
//        guard submittedStackView == nil else { return }

        // Pin directly to self — never use subviews[1] which can change
    private func ensureSubmittedStackExists() {
        guard submittedStackView == nil else { return }
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.ensureSubmittedStackExists() }
            return
        }

        let stack = UIStackView()
        stack.axis      = .vertical
        stack.spacing   = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stack)

        // Use viewforTextfields if available, otherwise fall back to self
        if let anchor = viewforTextfields {
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: anchor.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: anchor.trailingAnchor),
                stack.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 8),
            ])
        } else {
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: self.topAnchor, constant: 200),
            ])
        }
        submittedStackView = stack
        print("✅ [Stack] created, viewforTextfields=\(viewforTextfields != nil ? "OK" : "NIL")")
    }

    // MARK: - Update a single token name in-place (called by background resolution)
    func updateTokenName(_ name: String, for token: ApplicationToken) {
        guard AppNameResolution.isResolved(name) else { return }
        guard let index = appTokenItems.firstIndex(of: token) else { return }
        // Store in both arrays so submit and display both use the real name
        if index < appTokenNames.count {
            appTokenNames[index] = name
        }
        locallyResolvedNames[index] = name
        // Reload just this row — no full table reload, no flash
        let indexPath = IndexPath(row: index, section: 0)
        if tblViewLists.numberOfRows(inSection: 0) > index {
            tblViewLists.reloadRows(at: [indexPath], with: .none)
        }
        // If this is the currently selected row, refresh the overlay too
        if selectedIndex == index {
            showAppNameOverlay(token: token, at: index)
        }
        // Count down pending resolutions so Submit re-enables when all are done
        trackResolutionComplete()
    }

    /// Enables or disables the Submit (Send) button with a visual dim.
    /// Called externally by ChildHomeVC during name resolution.
    func setSubmitEnabled(_ enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.btnSend.isEnabled = enabled
            self.btnSend.alpha = enabled ? 1.0 : 0.4
        }
    }

    /// Call once per token whose name is being resolved in the background.
    /// Disables the Submit button until all pending resolutions complete.
    func trackResolutionPending() {
        pendingResolutionCount += 1
        if pendingResolutionCount > 0 {
            setSubmitEnabled(false)
        }
    }

    /// Call when a token's name resolution finishes (success or timeout).
    /// Re-enables the Submit button once all pending tokens are done.
    func trackResolutionComplete() {
        pendingResolutionCount = max(0, pendingResolutionCount - 1)
        if pendingResolutionCount == 0 {
            setSubmitEnabled(true)
        }
    }

    // MARK: - Clear text field after successful submission
    func clearUserNameTextField() {
        txtfield2.text = ""
    }

    // MARK: - Remove token from dropdown after submit
    func removeTokenFromDropdown(tokenString: String) {
        guard let matchIndex = tokenStringMap.first(where: { $0.value == tokenString })?.key else { return }

        if matchIndex < appTokenItems.count { appTokenItems.remove(at: matchIndex) }
        if matchIndex < appTokenNames.count { appTokenNames.remove(at: matchIndex) }

        var newMap: [Int: String] = [:]
        for (key, value) in tokenStringMap where key != matchIndex {
            let newKey = key > matchIndex ? key - 1 : key
            newMap[newKey] = value
        }
        tokenStringMap = newMap

        // Rebuild locallyResolvedNames with shifted indices
        var newResolved: [Int: String] = [:]
        for (key, value) in locallyResolvedNames where key != matchIndex {
            let newKey = key > matchIndex ? key - 1 : key
            newResolved[newKey] = value
        }
        locallyResolvedNames = newResolved

        selectedIndex = nil
        firstValue = nil
        clearSelectedNameOverlay()
        txtfield1.text = ""
        tblViewLists.reloadData()

        if appTokenItems.isEmpty {
            setEmptyState("All blocked apps have been requested.")
        }
    }

    // MARK: - Setup
    private func setup() {
        txtfield1.delegate = self
        txtfield2.delegate = self

        txtfield1.addTarget(self, action: #selector(openDropdown(_:)), for: .editingDidBegin)
        txtfield2.addTarget(self, action: #selector(openDropdown(_:)), for: .editingDidBegin)

        tblViewLists.delegate = self
        tblViewLists.dataSource = self

        tblViewLists.register(
            UINib(nibName: "CellForDurationList", bundle: nil),
            forCellReuseIdentifier: "CellForDurationList"
        )

        hideDropdown(animated: false)
    }

    // MARK: - Public Config
    func configure(
        showSecondField: Bool,
        firstPlaceholder: String,
        secondPlaceholder: String?
    ) {
        txtfield1.placeholder = firstPlaceholder
        txtfield2.placeholder = secondPlaceholder
        txtfield2.isHidden = !showSecondField
        cons_textfield2_height.constant = showSecondField ? 44 : 0
        layoutIfNeeded()
    }

    private func clearEmptyState() {
        emptyLabel?.removeFromSuperview()
        emptyLabel = nil
        for subview in viewforTableList.subviews {
            if subview.accessibilityIdentifier == "EmptyStateDivider" {
                subview.removeFromSuperview()
            }
        }
    }

    func setDropdownData(_ items: [String], listTitle: String? = nil) {
        isTokenMode = false
        dropdownItems = items
        appTokenItems = []
        appTokenNames = []
        tokenStringMap = [:]
        lblListTitle.text = listTitle
        selectedIndex = nil
        clearSelectedNameOverlay()
        clearEmptyState()
        loadingIndicator?.stopAnimating()
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
        tblViewLists.reloadData()
    }

    func setLoadingState(_ loading: Bool) {
        if loading {
            // Clear table
            isTokenMode = false
            dropdownItems = []
            appTokenItems = []
            appTokenNames = []
            tokenStringMap = [:]
            tblViewLists.reloadData()
            clearEmptyState()
            // Show spinner
            if loadingIndicator == nil {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.translatesAutoresizingMaskIntoConstraints = false
                viewforTableList.addSubview(spinner)
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: viewforTableList.centerXAnchor),
                    spinner.topAnchor.constraint(equalTo: viewforTableList.topAnchor, constant: 24)
                ])
                loadingIndicator = spinner
            }
            loadingIndicator?.startAnimating()
        } else {
            loadingIndicator?.stopAnimating()
            loadingIndicator?.removeFromSuperview()
            loadingIndicator = nil
        }
    }

    func setEmptyState(_ message: String) {
        isTokenMode = false
        dropdownItems = []
        appTokenItems = []
        appTokenNames = []
        tokenStringMap = [:]
        tblViewLists.reloadData()
        clearEmptyState()
        
        let lbl = UILabel()
        if message.lowercased().contains("no blocked") || message.lowercased().contains("all blocked") {
            lbl.text = "No blocked apps found"
        } else {
            lbl.text = message
        }
        lbl.textAlignment = .left
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = UIColor(named: "AppDarkBlue") ?? .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        viewforTableList.addSubview(lbl)
        
        // Create the divider/separator line to match the table cells
        let divider = UIView()
        divider.accessibilityIdentifier = "EmptyStateDivider"
        divider.backgroundColor = UIColor(named: "AppBorderGray") ?? UIColor.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        viewforTableList.addSubview(divider)
        
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: tblViewLists.topAnchor, constant: 16),
            lbl.leadingAnchor.constraint(equalTo: viewforTableList.leadingAnchor, constant: 20),
            lbl.trailingAnchor.constraint(equalTo: viewforTableList.trailingAnchor, constant: -20),
            
            divider.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: viewforTableList.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: viewforTableList.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        emptyLabel = lbl
    }

    func setTokenDropdownData(
        _ tokens: [ApplicationToken],
        tokenStrings: [String],
        listTitle: String? = nil,
        tokenNames: [String]? = nil
    ) {
        isTokenMode = true
        appTokenItems = tokens
        appTokenNames = tokenNames ?? Array(repeating: "", count: tokens.count)
        dropdownItems = []
        tokenStringMap = [:]
        locallyResolvedNames = [:]
        for (i, str) in tokenStrings.enumerated() {
            tokenStringMap[i] = str
        }
        lblListTitle.text = listTitle
        selectedIndex = nil
        clearSelectedNameOverlay()
        clearEmptyState()
        tblViewLists.reloadData()

        // Resolve names in background using ChildHomeViewModel's key-window approach.
        // After 2 s (icon requests complete), names populate one-by-one via updateAppName().
        // locallyResolvedNames is updated so the submit flow has real names.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await ChildHomeViewModel.shared.resolveNamesForTokens(tokens, tokenStrings: tokenStrings) { [weak self] index, name in
                guard let self = self else { return }
                self.locallyResolvedNames[index] = name
                if index < self.appTokenNames.count {
                    self.appTokenNames[index] = name
                }
                self.tblViewLists.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }

    func expandForLargeList() {
        let subviews = self.subviews
        if subviews.count >= 2 {
            let card = subviews[1]
            var f = card.frame
            let extra = (f.height * 0.40).rounded()
            f.origin.y    -= extra
            f.size.height += extra
            card.frame = f
        }
        for constraint in (viewforTableList?.constraints ?? []) {
            if constraint.firstAttribute == .height,
               constraint.relation == .equal,
               constraint.secondItem == nil {
                constraint.constant = (constraint.constant * 1.40).rounded()
                break
            }
        }
        layoutIfNeeded()
    }


    // MARK: - Dropdown
    @objc private func openDropdown(_ textField: UITextField) {
        if isTokenMode && textField == txtfield2 {
            return
        }
        clearEmptyState()
        activeTextField = textField
        selectedIndex = nil
        tblViewLists.reloadData()
        showDropdown()
    }

    private func showDropdown() {
        viewforTableList.isHidden = false
    }

    private func hideDropdown(animated: Bool = true) {
        viewforTableList.isHidden = true
    }

    // MARK: - Name Overlay Helpers

    /// Removes any existing name overlay from txtfield1
    private func clearSelectedNameOverlay() {
        selectedNameHC?.view.removeFromSuperview()
        selectedNameHC = nil
    }

    /// Shows the selected app icon + name over txtfield1.
    /// Uses the already-resolved name instantly if available; only falls back to async
    /// LabelWithNameCapture when the name is genuinely unknown.
    private func showAppNameOverlay(token: ApplicationToken, at index: Int) {
        clearSelectedNameOverlay()
        txtfield1.text = " "   // space keeps placeholder hidden while overlay shows the real name

        // ── Determine the best available name right now ─────────────────────
        var knownName: String? = nil

        // 1. Locally resolved (captured by LabelWithNameCapture in the cell this session)
        if let local = locallyResolvedNames[index], AppNameResolution.isResolved(local) {
            knownName = local
        }
        // 2. appTokenNames array (updated by background resolution)
        if knownName == nil, index < appTokenNames.count,
           AppNameResolution.isResolved(appTokenNames[index]) {
            knownName = appTokenNames[index]
        }
        // 3. Persistent cache (survives restarts)
        if knownName == nil,
           let tokenStr = tokenStringMap[index],
           let cached = AppNameResolutionCache.cachedName(forTokenStr: tokenStr) {
            knownName = cached
        }

        // ── Build the SwiftUI overlay with icon + name side by side ─────────
        let swiftUIOverlay: AnyView

        if let name = knownName {
            // ✅ Name already known — show immediately, no async polling
            swiftUIOverlay = AnyView(
                HStack(spacing: 10) {
                    Label(token)
                        .labelStyle(.iconOnly)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            )
        } else {
            // Name not yet cached — use ONE combined Label(token) for icon + title.
            // Single FamilyControlsAgent request; name appears once agent responds.
            swiftUIOverlay = AnyView(
                HStack(spacing: 10) {
                    Label(token)
                        .labelStyle(AppSelectionRowStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            )
        }

        embedNameOverlay(swiftUIOverlay)
    }


    private func embedNameOverlay(_ view: AnyView) {
        let hc = UIHostingController(rootView: view)
        // Opaque background hides the placeholder text underneath
        hc.view.backgroundColor = txtfield1.backgroundColor ?? .systemBackground
        hc.view.isUserInteractionEnabled = false
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        // Place on top of the text layer, not inside txtfield1, to avoid z-order issues
        txtfield1.superview?.insertSubview(hc.view, aboveSubview: txtfield1)
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: txtfield1.leadingAnchor, constant: 8),
            hc.view.trailingAnchor.constraint(equalTo: txtfield1.trailingAnchor, constant: -8),
            hc.view.topAnchor.constraint(equalTo: txtfield1.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: txtfield1.bottomAnchor),
        ])
        selectedNameHC = hc
    }
}

// MARK: - UITextFieldDelegate
extension ViewForReqAppSelection: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if isTokenMode && textField == txtfield2 {
            return true
        }
        openDropdown(textField)
        return false   // prevents keyboard
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Click Events
extension ViewForReqAppSelection {
    @IBAction func tapToSubmit(_ sender: UIButton) {
        guard let first = firstValue else {
            appDelegate.window?.rootViewController?.view.makeToast("Please select an app")
            return
        }

        // Prefer locally-resolved name (from Label(token) rendering in the cell)
        // over the server-stored name which may be "Unknown App"
        var name: String? = nil
        if isTokenMode, let idx = selectedIndex {
            // First try locally resolved (from LabelWithNameCapture in the cell)
            if let localName = locallyResolvedNames[idx], AppNameResolution.isResolved(localName) {
                name = localName
            } else if idx < appTokenNames.count, AppNameResolution.isResolved(appTokenNames[idx]) {
                // Fall back to appTokenNames (may have been updated by onNameResolved)
                name = appTokenNames[idx]
            }
            // ✔️ Final fallback: persistent cache — avoids "Could not identify" for any
            // app whose name was resolved in any previous session
            if name == nil {
                name = AppNameResolutionCache.cachedName(forTokenStr: first)
            }
        }

        if isTokenMode {
            let userNameText = txtfield2.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            onSubmit?(first, userNameText, name)
        } else if !txtfield2.isHidden {
            guard let second = secondValue else {
                appDelegate.window?.rootViewController?.view.makeToast("Please select a reason")
                return
            }
            onSubmit?(first, second, name)
        } else {
            onSubmit?(first, nil, name)
        }
    }

    @IBAction func tapToBackFromList(_ sender: UIControl) {
        hideDropdown()
    }

    @IBAction func tapToCloseView(_ sender: UIButton) {
        onCloseView?()
    }
}

// MARK: - UITableView Delegate & DataSource
extension ViewForReqAppSelection: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isTokenMode ? appTokenItems.count : dropdownItems.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // ── Dropdown list ────────────────────────────────────────────────────
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CellForDurationList",
            for: indexPath
        ) as! CellForDurationList

        if isTokenMode {
            let row = indexPath.row  // capture row to avoid stale-index after cell reuse
            let token = appTokenItems[row]
            let name = row < appTokenNames.count ? appTokenNames[row] : ""
            cell.configureWithToken(
                token,
                isSelected: row == selectedIndex,
                fallbackName: name
            )
            cell.onNameResolved = { [weak self] resolvedName in
                guard let self = self else { return }
                guard AppNameResolution.isResolved(resolvedName) else { return }
                guard let dynamicRow = self.appTokenItems.firstIndex(of: token) else { return }
                // Store locally-resolved name so submit uses it even if server had "Unknown App"
                self.locallyResolvedNames[dynamicRow] = resolvedName
                if dynamicRow < self.appTokenNames.count && self.appTokenNames[dynamicRow] != resolvedName {
                    self.appTokenNames[dynamicRow] = resolvedName
                    if self.selectedIndex == dynamicRow {
                        self.showAppNameOverlay(token: token, at: dynamicRow)
                    }

                    // Also update ChildHomeViewModel's local list so it propagates
                    if let idx = ChildHomeViewModel.shared.requestedApps.firstIndex(where: {
                        $0.getApplicationToken() == token
                    }) {
                        ChildHomeViewModel.shared.requestedApps[idx].name = resolvedName
                    }

                    // Reload only this row so the resolved name appears without a full reload
                    DispatchQueue.main.async {
                        self.tblViewLists.reloadRows(at: [IndexPath(row: dynamicRow, section: 0)],
                                                     with: .none)
                    }
                }
            }
        } else {
            cell.configureCell(
                dropdownItems[indexPath.row],
                isSelected: indexPath.row == selectedIndex
            )
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row

        let value: String
        if isTokenMode {
            value = tokenStringMap[indexPath.row] ?? ""
            showAppNameOverlay(token: appTokenItems[indexPath.row], at: indexPath.row)
            selectedType = "app"
        } else {
            value = dropdownItems[indexPath.row]
            activeTextField?.text = value
        }

        let fieldIndex = (activeTextField == txtfield1) ? 0 : 1

        if fieldIndex == 0 {
            firstValue = value
        } else {
            secondValue = value
        }

        onSelect?(fieldIndex, value)

        tableView.reloadData()
        hideDropdown()
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 55 }
}
