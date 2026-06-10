//
//  WeeklyBarChartView.swift
//  GaurdianDrive
//
//  Created by KETAN on 30/12/25.
//

import UIKit

class WeeklyBarChartView: UIView {

    
    // MARK: - Public API
    func configure(
        days: [String],
        greenValues: [CGFloat],
        redValues: [CGFloat],
        maxValue: CGFloat = 75
    ) {
        guard days.count == greenValues.count,
              days.count == redValues.count else { return }

        self.days = days
        self.greenValues = greenValues
        self.redValues = redValues
        self.maxValue = maxValue

        setNeedsDisplay()
    }

    // MARK: - Internal Data
    private var days: [String] = []
    private var greenValues: [CGFloat] = []
    private var redValues: [CGFloat] = []

    private var maxValue: CGFloat = 75
    private let yLabels: [CGFloat] = [0, 15, 30, 45, 60, 75]

    // MARK: - Layout
    private let leftPadding: CGFloat = 40
    private let bottomPadding: CGFloat = 30
    private let topPadding: CGFloat = 10

    private let barWidth: CGFloat = 9
    private let barSpacing: CGFloat = 0

    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        guard days.count > 0 else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let chartHeight = rect.height - bottomPadding - topPadding
        let chartWidth = rect.width - leftPadding
        
        let startX = leftPadding
        let startY = rect.height - bottomPadding
        
        let stepX = chartWidth / CGFloat(days.count + 1)
        let groupWidth = barWidth * 2 + barSpacing
        
        // ===============================
        // Y Axis Labels
        // ===============================
        for value in yLabels {
            let y = startY - (value / maxValue) * chartHeight
            let label = "\(Int(value))"
            
            label.draw(
                at: CGPoint(x: 5, y: y - 7),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.gray
                ]
            )
        }
        
        // ===============================
        // Vertical Grid Lines
        // ===============================
        ctx.setStrokeColor(UIColor.init(named:"AppBorderGray")!.cgColor)
        ctx.setLineWidth(1)
        
        for i in 0...days.count {
            let x = startX + stepX * CGFloat(i)
            ctx.move(to: CGPoint(x: x, y: topPadding))
            ctx.addLine(to: CGPoint(x: x, y: startY))
        }
        ctx.strokePath()
        
        // ===============================
        // Bottom Line
        // ===============================
        ctx.setStrokeColor(UIColor.systemGray3.cgColor)
        ctx.move(to: CGPoint(x: startX, y: startY))
        ctx.addLine(to: CGPoint(x: rect.width, y: startY))
        ctx.strokePath()
        
        // ===============================
        // Bars + Day Labels
        // ===============================
        for i in 0..<days.count {
            let centerX = startX + stepX * CGFloat(i + 1)
            
            let greenHeight = (greenValues[i] / maxValue) * chartHeight
            let redHeight = (redValues[i] / maxValue) * chartHeight
            
            let greenX = centerX - groupWidth / 2
            let redX = greenX + barWidth + barSpacing
            
            ctx.setFillColor(UIColor.init(named:"AppDarkGreen")!.cgColor)
            ctx.fill(CGRect(
                x: greenX,
                y: startY - greenHeight,
                width: barWidth,
                height: greenHeight
            ))
            
            ctx.setFillColor(UIColor.init(named:"AppRed")!.cgColor)
            ctx.fill(CGRect(
                x: redX,
                y: startY - redHeight,
                width: barWidth,
                height: redHeight
            ))
            
            let textSize = days[i].size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ])
            
            days[i].draw(
                at: CGPoint(x: centerX - textSize.width / 2, y: startY + 6),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: UIColor.gray
                ]
            )
        }
    }

}
