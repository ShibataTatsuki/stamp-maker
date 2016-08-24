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
    var labelArray: [UILabel] = []
    
    let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //AppDelegateのインスタンスを取得_
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myImageView.userInteractionEnabled = true
        
        Label.text = "Please deside your picture!"
        Label.textColor = UIColor.blueColor()
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
            
            let tapGesture = UITapGestureRecognizer(target: self, action: Selector("tap:"))
            faceOutline.addGestureRecognizer(tapGesture)
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
    func tap(gesture:UIPinchGestureRecognizer){
        myImageView.image = cropImageToSquare(myImageView.image!, faceLine: gesture.view!)
        let subviews = myImageView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }

    }
    @IBAction func back(){
        if faceOutlineArray.count > 0{
            self.faceOutlineArray.last!.removeFromSuperview()
            faceOutlineArray.removeLast()
        }
    }
    
    func cropImageToSquare(image: UIImage, faceLine: UIView) -> UIImage? {
        
        let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, faceLine.frame)
        
        return UIImage(CGImage: cropCGImageRef!)
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

    @IBAction func number1(){
        stampIndex = 1
    }

    @IBAction func uploadButtonTapped(sender: UIButton){
        guard let selectedPhoto = myImageView.image else{
            simpleAlert("画像がありません")
            return
        }
        for label in self.labelArray {
            self.myImageView.image = self.drawMaskLabel(label)
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
    
    func draw2MaskLabel(label: UILabel)->UIImage{
        UIGraphicsBeginImageContextWithOptions(myImageView.frame.size, false, UIScreen.mainScreen().scale)
        myImageView.addSubview(label)
        if let context = UIGraphicsGetCurrentContext() {
            myImageView.layer.renderInContext(context)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
        
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch: UITouch = touches.first!
        let location: CGPoint = touch.locationInView(self.myImageView)
        
        if stampIndex != 0 && touch.view!.tag == 0 && location.y <= myImageView.frame.maxY{
            let label = UILabel(frame: CGRectMake(0, 0, 150, 50))
            label.textAlignment = .Center
            label.text = appDelegate.mytext
            label.textColor = UIColor.redColor()
            //label.backgroundColor = UIColor.blueColor()
            label.center = CGPointMake(location.x, location.y)
            label.userInteractionEnabled = true
            label.tag = 1
            //ジェスチャーを宣言
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: Selector("changeScale:"))
            label.addGestureRecognizer(pinchGesture)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: Selector("drag:"))
            label.addGestureRecognizer(panGesture)
            
            labelArray.append(label)
            self.view.addSubview(label)

        }
    }
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        
//        let touch: UITouch = touches.first!
//        let location: CGPoint = touch.locationInView(self.myImageView)
//        faceOutline.layer.borderColor = UIColor.blueColor()().CGColor
//                }
    

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
