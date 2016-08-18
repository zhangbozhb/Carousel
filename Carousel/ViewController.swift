//
//  ViewController.swift
//  Carousel
//
//  Created by travel on 16/7/26.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CarouselViewDataSourse, CarouselViewDelegate {
    @IBOutlet weak var carousel: CarouselView!


    @IBOutlet weak var visiblePageCount: UILabel!
    @IBOutlet weak var slideVisiblePageCount: UISlider!
    
    @IBOutlet weak var slidePageCount: UISlider!
    @IBOutlet weak var pageCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        pageCountLabel.text = "Total Page: \(Int(slidePageCount.value))"
        visiblePageCount.text = "Visiable Page: \(Int(slideVisiblePageCount.value))"
        carousel.visiblePageCount = Int(slideVisiblePageCount.value)

//        carousel = CarouselView.init(frame: view.bounds)
//        view.addSubview(carousel)
        carousel.type = .Loop
        carousel.dataSource = self
        carousel.carouselDelegate = self
        carousel.reload()
        
        carousel.scrollToPage(0)
        carousel.autoScroll(2, increase: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfView(carousel: CarouselView) -> Int {
        return Int(slidePageCount.value)
    }
    
    func carousel(carousel:CarouselView, viewForIndex index:Int) -> UIView? {
        
        let padding:CGFloat = 20
        let v = UIView()
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
        return (index % 6 == 0 && index != 0) ? nil : v
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
        pageCountLabel.text = "Total Page: \(Int(sender.value))"
        carousel.reload()
    }
    
    @IBAction func changeVisibelPageCount(sender: UISlider) {
        visiblePageCount.text = "Visiable Page: \(Int(sender.value))"
        carousel.visiblePageCount = Int(sender.value)
        carousel.reload()
    }
    
    
    // CarouselViewDelegate
    func carousel(carousel: CarouselView, didScrollFrom: Int, to: Int) {
        print("CarouselView didScrollFrom \(didScrollFrom) \(to)")
    }
    
    func carousel(carousel: CarouselView, scrollFrom: Int, to: Int, progress: CGFloat) {
        print("CarouselView scrollFrom \(scrollFrom) \(to) \(progress)")
    }
}

