//
//  HomeViewController.swift
//  Dither-Swift
//
//  Created by 刘敏 on 2022/10/26.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet fileprivate weak var originalV: UIImageView!
    @IBOutlet fileprivate weak var ditherV: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // 新
    @IBAction func conversionA(_ sender: UIButton) {
        var ptype: PaletteType!
        if sender.tag == 100 {
            ptype = .BW
        }
        else if sender.tag == 101 {
            ptype = .BWR
        }
        else if sender.tag == 102 {
            ptype = .BWY
        }
        
        BMPTools.floydSteinberg(originalV.image!, type: ptype) { [weak self] img in
            self!.ditherV.image = img
        }
    }
    
    @IBAction func blackAndWhiteTapped(_ sender: UIButton) {
        BMPTools.blackAndWhite(originalV.image!) { [weak self] img in
            self!.ditherV.image = img
        }
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {
        UIImageWriteToSavedPhotosAlbum(ditherV.image!, nil, nil, nil)
    }
    
    
}

