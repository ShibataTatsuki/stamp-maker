//
//  makeViewController.swift
//  stampmaker
//
//  Created by 柴田　樹希 on 2016/08/21.
//  Copyright © 2016年 柴田　樹希. All rights reserved.
//

import UIKit
import CoreImage

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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.faceLoad()
        
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
        self.faceLoad()
        myImageView.image = nil
        
        
    }

    func faceLoad (){
        let baseImage = UIImage(named: "IMG_5168.JPG")!
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
                    myImageView.addSubview(faceOutline)
                }

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
