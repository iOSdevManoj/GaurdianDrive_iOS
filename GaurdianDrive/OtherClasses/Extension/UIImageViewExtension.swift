//
//  UIImageViewExtension.swift


import UIKit
import SDWebImage
extension UIImageView {
    
    
    //Create parallax effect
    func addParallax(verticalAmount:Float = 0.0 , horozontalAmount:Float = 0.0) {
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -horozontalAmount
        horizontal.maximumRelativeValue = horozontalAmount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -verticalAmount
        vertical.maximumRelativeValue = verticalAmount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        self.addMotionEffect(group)
    }
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
    
    func setImage(aUrlStr:String)  {
        let urlString1 = aUrlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) //This will fill the spaces with the %20
        self.sd_imageIndicator = SDWebImageActivityIndicator.gray
        self.sd_imageIndicator?.startAnimatingIndicator()
        if let urlString = URL(string:urlString1!){
            self.sd_setImage(with: urlString, placeholderImage: nil, options: .highPriority) { (img, error, cacheType, url) in
            self.sd_imageIndicator?.stopAnimatingIndicator()
            if img != nil {
                self.image = img
//                self.contentMode = .scaleAspectFit
                self.clipsToBounds = true
            }
        }
    }
    }
    func setImageFit(aUrlStr:String)  {
        let urlString1 = aUrlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) //This will fill the spaces with the %20
//        self.sd_imageIndicator = SDWebImageActivityIndicator.gray
//        self.sd_imageIndicator?.startAnimatingIndicator()
        self.sd_setImage(with: URL(string:urlString1!), placeholderImage: nil, options: .highPriority) { (img, error, cacheType, url) in
//            self.sd_imageIndicator?.stopAnimatingIndicator()
            if img != nil {
                self.image = img
                self.contentMode = .scaleAspectFit
                self.clipsToBounds = true
            }
        }
    }
}
extension UIImage {
    
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func compressTo(toSizeInKB: Double) -> UIImage? {
        let bytes = toSizeInKB  * 1024.0
        let sizeInBytes = Int(bytes)
        var needCompress:Bool = true
        var imgData:Data?
        var compressingValue:CGFloat = 1.0

        while (needCompress) {

            if let resizedImage = scaleImage(byMultiplicationFactorOf: compressingValue), let data: Data = resizedImage.jpegData(compressionQuality: compressingValue) {

                if data.count < sizeInBytes || compressingValue < 0.1 {
                    needCompress = false
                    imgData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }

        if let data = imgData {
            print("Finished with compression value of: \(compressingValue)")
            return UIImage(data: data)
        }
        return nil
    }
    private func scaleImage(byMultiplicationFactorOf factor: CGFloat) -> UIImage? {
        let size = CGSize(width: self.size.width*factor, height: self.size.height*factor)
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        if let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage;
        }
        return nil
    }
    func resizedTo1MB() -> UIImage? {
        //https://stackoverflow.com/questions/29137488/how-do-i-resize-the-uiimage-to-reduce-upload-image-size/29138120

        guard let imageData = self.pngData() else { return nil }
        
        var resizingImage = self
        var imageSizeKB = Double(imageData.count) / 1024.0 // ! Or devide for 1024 if you need KB but not kB
        
        while imageSizeKB > 1024.0 { // ! Or use 1024 if you need KB but not kB (1 MB = 1024 KB, 1536 KB = 1.5 MB)
            guard let resizedImage = resizingImage.resized(withPercentage: 0.5),
                let imageData =  resizedImage.pngData()
            
                else { return self}
            
            resizingImage = resizedImage
            imageSizeKB = Double(imageData.count) / 1024.0 // ! Or devide for 1024 if you need KB but not kB
        }
        return resizingImage
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if ( self.imageOrientation == UIImage.Orientation.up ) {
            return self;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        }
        
        if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        }
        
        if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
        }
        
        if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( self.imageOrientation == UIImage.Orientation.left ||
            self.imageOrientation == UIImage.Orientation.leftMirrored ||
            self.imageOrientation == UIImage.Orientation.right ||
            self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
}
//func returnImageFromUrl(imgUrl:String) -> UIImage
//{
//    let imgIcon = UIImageView()
//
//    imgIcon.sd_imageIndicator = SDWebImageActivityIndicator.gray
//
//    var urlString = imgUrl
//
//    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") && urlString != ""
//    {
//        urlString = WebURL.imageUrl + urlString
//    }
//    urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//    if let urlString = URL(string:urlString)
//    {
//        imgIcon.sd_setImage(with: urlString, placeholderImage:UIImage(named: "user_placeholder"))
//    }else{
//        imgIcon.image = UIImage(named: "user_placeholder")
//        imgIcon.sd_imageIndicator = nil
//    }
//    return imgIcon.image!
//}
