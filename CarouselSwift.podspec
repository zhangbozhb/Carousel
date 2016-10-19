#
#  pod spec lint CarouselSwift.podspec --allow-warnings
#  pod trunk push CarouselSwift.podspec --allow-warnings

Pod::Spec.new do |s|

    s.name         = "CarouselSwift"
    s.version      = "1.2"
    s.summary      = "An reusable carousel support both Horizontal and Vertical direction, and multi page as well"

    s.description  = <<-DESC
                       An reusable carousel optimized in memory, features with:
                       a, support both Horizontal and Vertical direction
                       b, support multi page in visible view
                       c, support Linear and Loop mode
                       DESC

    s.homepage     = "https://github.com/zhangbozhb/Carousel"


    s.license      = { :type => "MIT"}

    s.author             = { "travel" => "zhangbozhb@gmail.com" }
    s.social_media_url   = "http://twitter.com/travel_zh"

    s.ios.deployment_target = "8.0"

    s.source       = { :git => "https://github.com/zhangbozhb/Carousel.git", :tag => s.version }


    s.source_files  = ["Sources/*.swift"]
    s.exclude_files = "Sources/Exclude"
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
