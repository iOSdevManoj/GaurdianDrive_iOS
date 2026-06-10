//
//  ViewForNoDriveRequest.swift
//  GaurdianDrive
//
//  Created by KETAN on 16/02/26.
//

import UIKit

class ViewForNoDriveRequest: UIView {
    
    // MARK: - Outlets..
    @IBOutlet weak var txtDate: UITextField!
    @IBOutlet weak var txtStartTime: UITextField!
    @IBOutlet weak var txtEndTime: UITextField!
    @IBOutlet weak var txtReason: UITextField!
    @IBOutlet weak var btnSendReq: UIButton!
    
    // MARK: - Data
    private var reasons: [String] = []
    private let datePicker = UIDatePicker()
    private let startTimePicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()
    private let reasonPicker = UIPickerView()
    
    // MARK: - Callback
    var onSubmit: ((_ date: Date?, _ startTime: Date?, _ endTime: Date?, _ reason: String?) -> Void)?
    var onCloseView: (() -> Void)?
    var onTapDate: (() -> Void)?
    var onTapStartTime: (() -> Void)?
    var onTapEndTime: (() -> Void)?
    var onTapReason: (() -> Void)?
    
    private var selectedDate: Date?
    private var selectedStartTime: Date?
    private var selectedEndTime: Date?
    private var selectedReason: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    // MARK: - XIB Initialisation
    static func loadXib() -> ViewForNoDriveRequest {
        let nib = UINib(nibName: "ViewForNoDriveRequest", bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! ViewForNoDriveRequest
    }
    
    // MARK: - Setup
    private func setup() {
        
        txtDate.delegate = self
        txtStartTime.delegate = self
        txtEndTime.delegate = self
        txtReason.delegate = self
        
        txtDate.addTarget(self, action: #selector(beginEditing(_:)), for: .editingDidBegin)
        txtStartTime.addTarget(self, action: #selector(beginEditing(_:)), for: .editingDidBegin)
        txtEndTime.addTarget(self, action: #selector(beginEditing(_:)), for: .editingDidBegin)
        txtReason.addTarget(self, action: #selector(beginEditing(_:)), for: .editingDidBegin)
        
        setupPickers()
        
//        txtDate.reloadInputViews()
//        txtStartTime.reloadInputViews()
//        txtEndTime.reloadInputViews()
//        txtReason.reloadInputViews()

    }
    
//    private func setupPickers() {
//        
//        // Date Picker (Future only)
//        datePicker.datePickerMode = .date
////        datePicker.backgroundColor = .white
//        datePicker.setValue(UIColor.white, forKey: "backgroundColor")
//
//        datePicker.minimumDate = Date()
//        if #available(iOS 13.4, *) {
//            datePicker.preferredDatePickerStyle = .wheels
//        }
//        txtDate.inputView = datePicker
//        
//        // Start Time Picker
//        startTimePicker.datePickerMode = .time
////        startTimePicker.backgroundColor = .white
//        startTimePicker.setValue(UIColor.white, forKey: "backgroundColor")
//
//        if #available(iOS 13.4, *) {
//            startTimePicker.preferredDatePickerStyle = .wheels
//        }
//        txtStartTime.inputView = startTimePicker
//        
//        // End Time Picker (separate instance)
//        endTimePicker.datePickerMode = .time
////        endTimePicker.backgroundColor = .white
//        endTimePicker.setValue(UIColor.white, forKey: "backgroundColor")
//
//        if #available(iOS 13.4, *) {
//            endTimePicker.preferredDatePickerStyle = .wheels
//        }
//        txtEndTime.inputView = endTimePicker
//        
//        // Reason Picker
//        reasonPicker.delegate = self
//        reasonPicker.dataSource = self
//        reasonPicker.backgroundColor = .white
//        txtReason.inputView = reasonPicker
//    }
    private func setupPickers() {

        let pickerHeight: CGFloat = 216

        // DATE PICKER
        let dateContainer = UIView()
        dateContainer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: pickerHeight)
        dateContainer.backgroundColor = .white
        dateContainer.autoresizingMask = [.flexibleWidth]

        datePicker.frame = dateContainer.bounds
        datePicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.backgroundColor = .white
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        dateContainer.addSubview(datePicker)
        txtDate.inputView = dateContainer


        // START TIME PICKER
        let startContainer = UIView()
        startContainer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: pickerHeight)
        startContainer.backgroundColor = .white
        startContainer.autoresizingMask = [.flexibleWidth]

        startTimePicker.frame = startContainer.bounds
        startTimePicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        startTimePicker.datePickerMode = .time
        startTimePicker.backgroundColor = .white
        if #available(iOS 13.4, *) {
            startTimePicker.preferredDatePickerStyle = .wheels
        }
        startContainer.addSubview(startTimePicker)
        txtStartTime.inputView = startContainer


        // END TIME PICKER
        let endContainer = UIView()
        endContainer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: pickerHeight)
        endContainer.backgroundColor = .white
        endContainer.autoresizingMask = [.flexibleWidth]

        endTimePicker.frame = endContainer.bounds
        endTimePicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        endTimePicker.datePickerMode = .time
        endTimePicker.backgroundColor = .white
        if #available(iOS 13.4, *) {
            endTimePicker.preferredDatePickerStyle = .wheels
        }
        endContainer.addSubview(endTimePicker)
        txtEndTime.inputView = endContainer


        // REASON PICKER
        let reasonContainer = UIView()
        reasonContainer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: pickerHeight)
        reasonContainer.backgroundColor = .white
        reasonContainer.autoresizingMask = [.flexibleWidth]

        reasonPicker.frame = reasonContainer.bounds
        reasonPicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        reasonPicker.backgroundColor = .white
        reasonPicker.delegate = self
        reasonPicker.dataSource = self
        reasonContainer.addSubview(reasonPicker)
        txtReason.inputView = reasonContainer
    }
    
    // MARK: - Public Config
    func setReasonList(_ list: [String]) {
        reasons = list
        reasonPicker.reloadAllComponents()
        if !reasons.isEmpty {
            selectedReason = reasons[0]
            txtReason.text = reasons[0]
        }
    }
}

// MARK: - UITextField Delegates
extension ViewForNoDriveRequest: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        beginEditing(textField)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let now = Date()
        let calendar = Calendar.current
        
        if textField == txtDate {
            
            let pickedDate = datePicker.date
            
            if pickedDate < now {
                datePicker.date = now
                selectedDate = now
            } else {
                selectedDate = pickedDate
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            txtDate.text = formatter.string(from: selectedDate ?? now)
        }
        
        else if textField == txtStartTime {
            
            let pickedTime = startTimePicker.date
            
            guard let selectedDate else {
                startTimePicker.setDate(now, animated: true)
                selectedStartTime = now
                updateStartTimeText(now)
                return
            }
            
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = calendar.component(.hour, from: pickedTime)
            components.minute = calendar.component(.minute, from: pickedTime)
            
            let combined = calendar.date(from: components) ?? now
            
            if calendar.isDateInToday(selectedDate) && combined < now {
                startTimePicker.setDate(now, animated: true)
                selectedStartTime = now
                updateStartTimeText(now)
            } else {
                selectedStartTime = pickedTime
                updateStartTimeText(pickedTime)
            }
            
            // Reset end time if it is earlier than new start time
            if let end = selectedEndTime {
                let startCombined = calendar.date(from: components)
                var endComp = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                endComp.hour = calendar.component(.hour, from: end)
                endComp.minute = calendar.component(.minute, from: end)
                let endCombined = calendar.date(from: endComp)
                
                if let s = startCombined, let e = endCombined, e <= s {
                    selectedEndTime = nil
                    txtEndTime.text = ""
                }
            }
        }
        
        else if textField == txtEndTime {
            
            let pickedTime = endTimePicker.date
            
            guard let selectedDate, let selectedStartTime else {
                selectedEndTime = nil
                txtEndTime.text = ""
                return
            }
            
            var startComp = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            startComp.hour = calendar.component(.hour, from: selectedStartTime)
            startComp.minute = calendar.component(.minute, from: selectedStartTime)
            
            var endComp = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            endComp.hour = calendar.component(.hour, from: pickedTime)
            endComp.minute = calendar.component(.minute, from: pickedTime)
            
            let startCombined = calendar.date(from: startComp) ?? now
            let endCombined = calendar.date(from: endComp) ?? now
            
            // End time must be greater than start time
            if endCombined <= startCombined {
                endTimePicker.setDate(selectedStartTime, animated: true)
                selectedEndTime = selectedStartTime
                updateEndTimeText(selectedStartTime)
            } else {
                selectedEndTime = pickedTime
                updateEndTimeText(pickedTime)
            }
        }
        
        else if textField == txtReason {
            if reasons.count > 0 {
                let row = reasonPicker.selectedRow(inComponent: 0)
                if row >= 0 && row < reasons.count {
                    selectedReason = reasons[row]
                    txtReason.text = reasons[row]
                }
            }
        }
    }
    
    // MARK: - Begin Editing Callback
    @objc private func beginEditing(_ textField: UITextField) {
        if textField == txtDate {
            onTapDate?()
        } else if textField == txtStartTime {
            onTapStartTime?()
        } else if textField == txtEndTime {
            onTapEndTime?()
        } else if textField == txtReason {
            onTapReason?()
        }
    }
    
    private func updateStartTimeText(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        txtStartTime.text = formatter.string(from: date)
    }
    
    private func updateEndTimeText(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        txtEndTime.text = formatter.string(from: date)
    }
}

// MARK: - Click events
extension ViewForNoDriveRequest {
    
    @IBAction func tapToSubmitRequest(_ sender: UIButton) {
        onSubmit?(selectedDate, selectedStartTime, selectedEndTime, selectedReason)
    }
    
    @IBAction func tapToCloseView(_ sender: UIButton) {
        endEditing(true)
        onCloseView?()
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension ViewForNoDriveRequest: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return reasons.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return reasons[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedReason = reasons[row]
        txtReason.text = reasons[row]
    }
}
