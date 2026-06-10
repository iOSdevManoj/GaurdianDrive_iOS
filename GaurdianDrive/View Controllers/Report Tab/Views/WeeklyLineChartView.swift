//
//  WeeklyLineChartView.swift
//  GaurdianDrive
//
//  Created by KETAN on 30/12/25.
//

import UIKit

class WeeklyLineChartView: UIView {

    // MARK: - Data
       private var values: [CGFloat] = []
      // private let days = ["M", "T", "W", "T", "F", "S", "S"]
       var days: [String] = []
       private let ySteps: [CGFloat] = [0, 15, 30, 45, 60, 75]
       private let maxValue: CGFloat = 75

       // MARK: - Padding
       private let leftPadding: CGFloat = 44
       private let rightPadding: CGFloat = 20
       private let topPadding: CGFloat = 20
       private let bottomPadding: CGFloat = 42

       // MARK: - Draw
       override func draw(_ rect: CGRect) {
           super.draw(rect)
           guard values.count > 1 else { return }

           layer.sublayers?.removeAll()

          // drawBorder()
           drawVerticalLines()
           drawXAxisLine()        // ✅ SINGLE horizontal line
           drawYAxisLabels()
           drawXAxisLabels()
           drawSmoothLine()
       }

//       // MARK: - Public API
//       func setData(_ data: [CGFloat]) {
//           values = data
//           DispatchQueue.main.async {
//               self.setNeedsDisplay()
//           }
//       }
    func setData(values: [CGFloat], days: [String]) {
        self.values = values
        self.days = days
        
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

       // MARK: - Chart Area
       private func contentRect() -> CGRect {
           return CGRect(
               x: leftPadding,
               y: topPadding,
               width: bounds.width - leftPadding - rightPadding,
               height: bounds.height - topPadding - bottomPadding
           )
       }

       // MARK: - Border
       private func drawBorder() {
           let border = CAShapeLayer()
           border.path = UIBezierPath(roundedRect: bounds, cornerRadius: 22).cgPath
           border.strokeColor = UIColor.systemBlue.cgColor
           border.fillColor = UIColor.clear.cgColor
           border.lineWidth = 2
           layer.addSublayer(border)
       }

       // MARK: - Vertical Lines (exactly days.count + 1)
       private func drawVerticalLines() {
           let rect = contentRect()
           let path = UIBezierPath()
           let spacing = rect.width / CGFloat(days.count)

           for i in 0...days.count {
               let x = rect.minX + CGFloat(i) * spacing
               path.move(to: CGPoint(x: x, y: rect.minY))
               path.addLine(to: CGPoint(x: x, y: rect.maxY))
           }

           let lines = CAShapeLayer()
           lines.path = path.cgPath
           lines.strokeColor = UIColor.systemGray5.cgColor
           lines.lineWidth = 1
           layer.addSublayer(lines)
       }

       // MARK: - SINGLE Horizontal Line (X-axis)
       private func drawXAxisLine() {
           let rect = contentRect()

           let path = UIBezierPath()
           path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
           path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

           let axis = CAShapeLayer()
           axis.path = path.cgPath
           axis.strokeColor = UIColor.systemGray4.cgColor
           axis.lineWidth = 1

           layer.addSublayer(axis)
       }

       // MARK: - Y Axis Labels
       private func drawYAxisLabels() {
           let rect = contentRect()

           for value in ySteps {
               let y = rect.maxY - (value / maxValue * rect.height)

               let label = CATextLayer()
               label.string = "\(Int(value))"
               label.fontSize = 12
               label.alignmentMode = .right
               label.foregroundColor = UIColor.systemGray.cgColor
               label.contentsScale = UIScreen.main.scale
               label.frame = CGRect(x: 6, y: y - 8, width: 32, height: 16)

               layer.addSublayer(label)
           }
       }

       // MARK: - X Axis Labels
       private func drawXAxisLabels() {
           let rect = contentRect()
           let spacing = rect.width / CGFloat(days.count)

           for i in 0..<days.count {
               let label = CATextLayer()
               label.string = days[i]
               label.fontSize = 12
               label.alignmentMode = .center
               label.foregroundColor = UIColor.systemGray.cgColor
               label.contentsScale = UIScreen.main.scale

               let centerX = rect.minX + CGFloat(i) * spacing + spacing / 2
               label.frame = CGRect(x: centerX - 8, y: rect.maxY + 10, width: 16, height: 14)
               layer.addSublayer(label)
           }
       }

       // MARK: - Smooth Line
       private func drawSmoothLine() {
           let rect = contentRect()
           let path = UIBezierPath()
           let spacing = rect.width / CGFloat(values.count - 1)

           for i in 0..<values.count {
               let x = rect.minX + CGFloat(i) * spacing
               let y = rect.maxY - (values[i] / maxValue * rect.height)
               let point = CGPoint(x: x, y: y)

               if i == 0 {
                   path.move(to: point)
               } else {
                   let prevX = rect.minX + CGFloat(i - 1) * spacing
                   let prevY = rect.maxY - (values[i - 1] / maxValue * rect.height)

                   let cp1 = CGPoint(x: (prevX + x) / 2, y: prevY)
                   let cp2 = CGPoint(x: (prevX + x) / 2, y: y)

                   path.addCurve(to: point, controlPoint1: cp1, controlPoint2: cp2)
               }
           }

           let line = CAShapeLayer()
           line.path = path.cgPath
           line.strokeColor = UIColor.systemBlue.cgColor
           line.fillColor = UIColor.clear.cgColor
           line.lineWidth = 3
           line.lineCap = .round
           line.lineJoin = .round

           layer.addSublayer(line)
       }
}
