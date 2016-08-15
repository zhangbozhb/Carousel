//
//  ViewController.swift
//  Carousel
//
//  Created by travel on 16/7/26.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CarouselScrollViewDataSourse {
    @IBOutlet weak var carousel: CarouselScrollView!

    @IBOutlet weak var slidePageCount: UISlider!
    
    @IBOutlet weak var pageCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        carousel.type = .Loop
        carousel.dataSource = self
        carousel.scrollToPage(0)
        carousel.reload()
        
        carousel.autoScroll(3, increase: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfView(carousel: CarouselScrollView) -> Int {
        return Int(slidePageCount.value)
    }
    
    func carousel(carousel: CarouselScrollView, viewForIndex: Int) -> UIView? {
        
        let padding:CGFloat = 20
        let v = UIView()
        v.backgroundColor = UIColor.orangeColor()
        
        
        let label = UILabel()
        label.text = "Page \(viewForIndex)"
        label.backgroundColor = UIColor.purpleColor()
        v.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        let w = label.heightAnchor.constraintEqualToAnchor(v.heightAnchor, multiplier: 1, constant: -padding * 2)
        let h = label.widthAnchor.constraintEqualToAnchor(v.widthAnchor, multiplier: 1, constant: -padding * 2)
        let cx = label.centerXAnchor.constraintEqualToAnchor(v.centerXAnchor)
        let cy = label.centerYAnchor.constraintEqualToAnchor(v.centerYAnchor)
        
        NSLayoutConstraint.activateConstraints([w, h, cx, cy])
//        label.addConstraints([w, h, cx, cy])
        v.layer.borderColor = UIColor.redColor().CGColor
        v.layer.borderWidth = 1
        return v
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        carousel.reload()
    }
    
    @IBAction func changeDirection(sender: UISwitch) {
        carousel.direction =  sender.on ? .Horizontal : .Vertical
        carousel.reload()
    }
    
    @IBAction func changeType(sender: UISwitch) {
        carousel.type =  sender.on ? .Loop : .Linear
        carousel.reload()
    }
    
    var preDouble:Double = -1
    @IBAction func changePage(sender: UIStepper) {
        if preDouble < sender.value {
            carousel.nextPage(true)
        } else {
            carousel.prePage(true)
        }
        preDouble = sender.value
    }
    
    @IBAction func changAutoScroll(sender: UISwitch) {
        if sender.on {
            carousel.autoScroll(3, increase: true)
        } else {
            carousel.stopAutoScroll()
        }
    }
    
    @IBAction func changePageCount(sender: UISlider) {
        pageCountLabel.text = "Count: \(Int(sender.value))"
        carousel.reload()
    }
    
}

