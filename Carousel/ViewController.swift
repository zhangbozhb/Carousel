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
        
        pageCountLabel.text = "Total Cell: \(Int(slidePageCount.value))"
        visiblePageCount.text = "Cell PerPage: \(Int(slideVisiblePageCount.value))"
        carousel.cellPerPage = Int(slideVisiblePageCount.value)

//        carousel = CarouselView.init(frame: view.bounds)
//        view.addSubview(carousel)
        carousel.type = .loop
        carousel.dataSource = self
        carousel.delegate = self
        carousel.pagingType = .cellLimit
        carousel.reload()

        carousel.autoScroll(2, increase: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfView(_ carousel: CarouselView) -> Int {
        return Int(slidePageCount.value)
    }
    
    func carousel(_ carousel:CarouselView, viewForIndex index:Int) -> UIView? {
        
        let padding:CGFloat = 20
        let v = UIView()
        v.backgroundColor = UIColor.orange
        
        
        let label = UILabel()
        label.textAlignment = .center
        label.text = "P \(index)"
        label.backgroundColor = UIColor.purple
        v.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        let w = label.heightAnchor.constraint(equalTo: v.heightAnchor, multiplier: 1, constant: -padding * 2)
        let h = label.widthAnchor.constraint(equalTo: v.widthAnchor, multiplier: 1, constant: -padding * 2)
        let cx = label.centerXAnchor.constraint(equalTo: v.centerXAnchor)
        let cy = label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        
        NSLayoutConstraint.activate([w, h, cx, cy])
        v.layer.borderColor = UIColor.red.cgColor
        v.layer.borderWidth = 1
        return (index % 6 == 0 && index != 0) ? nil : v
    }
    
    @IBAction func changeDirection(_ sender: UISwitch) {
        carousel.direction =  sender.isOn ? .horizontal : .vertical
        carousel.reload()
    }
    
    @IBAction func changeType(_ sender: UISwitch) {
        carousel.type =  sender.isOn ? .loop : .linear
        carousel.reload()
    }
    
    var preDouble:Double = -1
    @IBAction func changePage(_ sender: UIStepper) {
        if preDouble < sender.value {
            carousel.nextCell(true)
        } else {
            carousel.nextCell(true)
        }
        preDouble = sender.value
    }
    
    @IBAction func changAutoScroll(_ sender: UISwitch) {
        if sender.isOn {
            carousel.autoScroll(3, increase: true)
        } else {
            carousel.stopAutoScroll()
        }
    }
    
    @IBAction func changePageCount(_ sender: UISlider) {
        pageCountLabel.text = "Total Cell: \(Int(sender.value))"
        carousel.reload()
    }
    
    @IBAction func changeVisibelPageCount(_ sender: UISlider) {
        visiblePageCount.text = "Cell PerPage: \(Int(sender.value))"
        carousel.cellPerPage = Int(sender.value)
        carousel.reload()
    }
    
    
    // CarouselViewDelegate
    func carousel(_ carousel: CarouselView, didScrollFrom: Int, to: Int) {
        print("CarouselView didScrollFrom \(didScrollFrom) \(to)")
    }
    
    func carousel(_ carousel: CarouselView, scrollFrom: Int, to: Int, progress: CGFloat) {
        print("CarouselView scrollFrom \(scrollFrom) \(to) \(progress)")
    }
}

