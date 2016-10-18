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
        
        self.type = .loop
        self.reload()
        
        self.autoScroll(2, increase: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    func numberOfViewController(_ carousel: CarouselViewController) -> Int {
        return 10
    }
    
    func carousel(_ carousel:CarouselViewController, viewControllerForIndex index:Int) -> UIViewController? {
        let padding:CGFloat = 20
        let vc = UIViewController()
        let v = vc.view
        v?.backgroundColor = UIColor.orange
        
        
        let label = UILabel()
        label.textAlignment = .center
        label.text = "P \(index)"
        label.backgroundColor = UIColor.purple
        v?.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        let w = label.heightAnchor.constraint(equalTo: (v?.heightAnchor)!, multiplier: 1, constant: -padding * 2)
        let h = label.widthAnchor.constraint(equalTo: (v?.widthAnchor)!, multiplier: 1, constant: -padding * 2)
        let cx = label.centerXAnchor.constraint(equalTo: (v?.centerXAnchor)!)
        let cy = label.centerYAnchor.constraint(equalTo: (v?.centerYAnchor)!)
        
        NSLayoutConstraint.activate([w, h, cx, cy])
        v?.layer.borderColor = UIColor.red.cgColor
        v?.layer.borderWidth = 1

        return vc
    }

    
    func carousel(_ carousel: CarouselViewController, didScrollFrom: Int, to: Int) {
        print("CarouselViewController didScrollFrom \(didScrollFrom) \(to)")
    }
    
    func carousel(_ carousel: CarouselViewController, scrollFrom: Int, to: Int, progress: CGFloat) {
        print("CarouselViewController scrollFrom \(scrollFrom) \(to) \(progress)")
    }
    
    func carousel(_ carousel: CarouselViewController, didTapAt cell: Int) {
        print("CarouselViewController didTapAt \(cell)")
    }
}
