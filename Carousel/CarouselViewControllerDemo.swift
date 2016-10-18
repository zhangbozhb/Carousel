//
//  CarouselViewControllerDemo.swift
//  Carousel
//
//  Created by travel on 16/8/18.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit

class CarouselViewControllerDemo: CarouselViewController, CarouselViewControllerDataSourse, CarouselViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        self.type = .Loop
        self.reload()
        
        self.autoScroll(2, increase: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    func numberOfViewController(carousel: CarouselViewController) -> Int {
        return 10
    }
    
    func carousel(carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController? {
        let padding:CGFloat = 20
        let vc = UIViewController()
        let v = vc.view
        v.backgroundColor = UIColor.orangeColor()
        
        
        let label = UILabel()
        label.textAlignment = .Center
        label.text = "P \(index)"
        label.backgroundColor = UIColor.purpleColor()
        v.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        let w = label.heightAnchor.constraintEqualToAnchor(v.heightAnchor, multiplier: 1, constant: -padding * 2)
        let h = label.widthAnchor.constraintEqualToAnchor(v.widthAnchor, multiplier: 1, constant: -padding * 2)
        let cx = label.centerXAnchor.constraintEqualToAnchor(v.centerXAnchor)
        let cy = label.centerYAnchor.constraintEqualToAnchor(v.centerYAnchor)
        
        NSLayoutConstraint.activateConstraints([w, h, cx, cy])
        v.layer.borderColor = UIColor.redColor().CGColor
        v.layer.borderWidth = 1

        return vc
    }

    
    func carousel(carousel: CarouselViewController, didScrollFrom: Int, to: Int) {
        print("CarouselViewController didScrollFrom \(didScrollFrom) \(to)")
    }
    
    func carousel(carousel: CarouselViewController, scrollFrom: Int, to: Int, progress: CGFloat) {
        print("CarouselViewController scrollFrom \(scrollFrom) \(to) \(progress)")
    }
    
    func carousel(carousel: CarouselViewController, didTapAt cell: Int) {
        print("CarouselViewController didTapAt \(cell)")
    }
}
