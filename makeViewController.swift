//
//  makeViewController.swift
//  stampmaker
//
//  Created by 柴田　樹希 on 2016/08/21.
//  Copyright © 2016年 柴田　樹希. All rights reserved.
//

import UIKit
import CoreImage
import Social

extension UIImage{
    
    // UIImageをリサイズするメソッド.
    class func ResizeÜIImage(image : UIImage,width : CGFloat, height : CGFloat)-> UIImage!{
        
        // 指定された画像の大きさのコンテキストを用意.
        UIGraphicsBeginImageContext(CGSizeMake(width, height))
        
        // コンテキストに自身に設定された画像を描画する.
        image.drawInRect(CGRectMake(0, 0, width, height))
        
        // コンテキストからUIImageを作る.
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // コンテキストを閉じる.
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}

class makeViewController: UIViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    @IBOutlet var myImageView: UIImageView!
    @IBOutlet var Label: UILabel!
    var faceOutlineArray: [UIView] = []
    var stampIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myImageView.userInteractionEnabled = true

        Label.text = "写真を選択してください！"
    }
    
    func presentPickerController(sourceType:UIImagePickerControllerSourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = sourceType
            self.presentViewController(picker,animated: true, completion: nil)
        }
    }
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo:NSDictionary!) {
        self .dismissViewControllerAnimated(true, completion: nil)
        myImageView.image = image
        let subviews = myImageView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        Label.hidden = true
        self.faceLoad()
        
        
    }
    
    
    @IBAction func picture(sender: UIButton){
        
        let alertController = UIAlertController(title: "画像の取得先を選択", message: nil, preferredStyle: .ActionSheet)
        let firstAction = UIAlertAction(title: "カメラ", style: .Default){
            action in
            self.presentPickerController(.Camera)
        }
        let secondAction = UIAlertAction(title: "アルバム", style: .Default){
            action in
            self.presentPickerController(.PhotoLibrary)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
        
        alertController.addAction(firstAction)
        alertController.addAction(secondAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
        
        
        
    }
    
    func faceLoad (){
        let baseImage = myImageView.image!
        let myImage : UIImage = UIImage.ResizeÜIImage(baseImage, width: self.view.frame.width, height: (self.view.frame.width/baseImage.size.width )*baseImage.size.height)
        
        // Do any additional setup after loading the view.
        // NSDictionary型のoptionを生成。顔認識の精度を追加する.
        let options : NSDictionary = NSDictionary(object: CIDetectorAccuracyHigh, forKey: CIDetectorAccuracy)
        
        // CIDetectorを生成。顔認識をするのでTypeはCIDetectorTypeFace.
        let detector : CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options as? [String : AnyObject])
        
        myImageView.frame = CGRectMake(0, 0, myImage.size.width, myImage.size.height)
        myImageView.center = self.view.center
        myImageView.image = myImage
        
        
        // detectorで認識した顔のデータを入れておくNSArray.
        let faces : NSArray = detector.featuresInImage(CIImage(image: myImage)!)
        
        // UIKitは画面左上に原点があるが、CoreImageは画面左下に原点があるのでそれを揃えなくてはならない.
        // CoreImageとUIKitの原点を画面左上に統一する処理.
        var transform : CGAffineTransform = CGAffineTransformMakeScale(1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -myImageView.bounds.size.height)
        
        // 検出された顔のデータをCIFaceFeatureで処理.
        var feature : CIFaceFeature = CIFaceFeature()
        for feature in faces {
            
            // 座標変換.
            let faceRect : CGRect = CGRectApplyAffineTransform(feature.bounds, transform)
            print(faceRect)
            
            
            // 画像の顔の周りを線で囲うUIViewを生成.
            let faceOutline = UIView(frame: faceRect)
            faceOutline.layer.borderWidth = 1
            faceOutline.layer.borderColor = UIColor.redColor().CGColor
            faceOutline.transform = CGAffineTransformMakeScale(2, 2)
            
            
            //ジェスチャーを宣言
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: Selector("changeScale:"))
            faceOutline.addGestureRecognizer(pinchGesture)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: Selector("drag:"))
            faceOutline.addGestureRecognizer(panGesture)
            
            faceOutlineArray.append(faceOutline)
            myImageView.addSubview(faceOutline)
            
        }

    }
    func changeScale(gesture:UIPinchGestureRecognizer){
        gesture.view?.transform = CGAffineTransformMakeScale(gesture.scale, gesture.scale)
    }
    
    func drag(gesture:UIPanGestureRecognizer){
        var point: CGPoint = gesture.translationInView(self.view)
        var movedPoint: CGPoint = CGPointMake(gesture.view!.center.x + point.x,gesture.view!.center.y + point.y)
        //if movedPoint.x >= 0 && movedPoint.y >= 0 && movedPoint.x <= myImageView.frame.width && movedPoint.y <= myImageView.frame.height{
            gesture.view!.center = movedPoint
      //  }
        gesture.setTranslation(CGPointZero, inView: self.view)
    }
    @IBAction func back(){
        if faceOutlineArray.count > 0{
            self.faceOutlineArray.last!.removeFromSuperview()
            faceOutlineArray.removeLast()
        }
    }
    
    
    @IBAction func cut (){
        self.cropImageToSquare(myImageView.image!)
    }
    func cropImageToSquare(image: UIImage) -> UIImage? {
        if image.size.width > image.size.height {
            // 横長
            let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(image.size.width/2 - image.size.height/2, 0, image.size.height, image.size.height))
            
            return UIImage(CGImage: cropCGImageRef!)
        } else if image.size.width < image.size.height {
            // 縦長
            let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, image.size.width, image.size.width))
            
            return UIImage(CGImage: cropCGImageRef!)
        } else {
            return image
        }
    }
    func simpleAlert(titleString: String){
        let alertController = UIAlertController(title: titleString, message: nil, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        
        presentViewController(alertController, animated:true , completion:nil )
    }
    
    
    func postToSNS(serviceType: String){
        let myComposeView = SLComposeViewController(forServiceType: serviceType)
        myComposeView.setInitialText("PhotoMasterからの投稿✨")
        myComposeView.addImage(myImageView.image)
        self.presentViewController(myComposeView, animated: true, completion: nil)
    }
    @IBAction func uploadButtonTapped(sender: UIButton){
        guard let selectedPhoto = myImageView.image else{
            simpleAlert("画像がありません")
            return
        }
        
        let alertController = UIAlertController(title: "アップロード先を選択", message: nil, preferredStyle: .ActionSheet)
        let firstAction = UIAlertAction(title: "Facebookに投稿", style: .Default){
            action in
            self.postToSNS(SLServiceTypeFacebook)
        }
        let secondAction = UIAlertAction(title: "twitterに投稿", style: .Default){
            action in
            self.postToSNS(SLServiceTypeTwitter)
        }
        let thirdAction = UIAlertAction(title: "カメラロールに保存", style: .Default){
            
            action in
            UIImageWriteToSavedPhotosAlbum(selectedPhoto,self,nil,nil)
            self.simpleAlert("アルバムに保存されました。")
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
        
        alertController.addAction(firstAction)
        alertController.addAction(secondAction)
        alertController.addAction(thirdAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func drawMaskLabel(label: UILabel)->UIImage{
        UIGraphicsBeginImageContextWithOptions(myImageView.frame.size, false, UIScreen.mainScreen().scale)
        myImageView.addSubview(label)
        if let context = UIGraphicsGetCurrentContext() {
            myImageView.layer.renderInContext(context)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
