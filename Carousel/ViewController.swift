//
//  ViewController.swift
//  Carousel
//
//  Created by travel on 16/7/26.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CarouselScrollViewDataSourse {
    lazy var carousel:CarouselScrollView = self.creatCarouselScrollView()
    
    func creatCarouselScrollView() -> CarouselScrollView {
        let carousel = CarouselScrollView.init(frame: CGRectMake(50, 100, view.bounds.width - 100, view.bounds.height - 200))
        view.addSubview(carousel)
        carousel.backgroundColor = UIColor.yellowColor()
//        carousel.direction = .Vertical
        carousel.type = .Loop
        carousel.dataSource = self
        
        return carousel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        carousel.dataSource = self
        carousel.scrollToPge(0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfView(carousel: CarouselScrollView) -> Int {
        return 4
    }
    
    func carousel(carousel: CarouselScrollView, viewForIndex: Int) -> UIView? {
        
        if carousel.direction == .Horizontal {
            let vf = CGRectMake(10, 50, carousel.frame.width/CGFloat(carousel.visiblePage)-20, carousel.frame.height - 100)
            let v = UIView.init(frame: vf)
            let label = UILabel.init(frame: CGRectMake(5, 5, v.frame.width-5, v.frame.height-5))
            label.text = "Page \(viewForIndex)"
            label.backgroundColor = UIColor.purpleColor()
            v.addSubview(label)
            label.center = v.center
            v.backgroundColor = UIColor.orangeColor()
            return v
        } else {
            let vf = CGRectMake(10, 10, carousel.frame.width - 10, carousel.frame.height/CGFloat(carousel.visiblePage)-20)
            let v = UIView.init(frame: vf)
            let label = UILabel.init(frame: CGRectMake(5, 5, v.frame.width-5, v.frame.height-5))
            label.text = "Page \(viewForIndex)"
            label.backgroundColor = UIColor.purpleColor()
            v.addSubview(label)
            label.center = v.center
            v.backgroundColor = UIColor.orangeColor()
            return v
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        print("\(carousel.firstVisiblePageViews?.validPage) \(carousel.lastVisiblePageViews?.validPage)")
    }

}

