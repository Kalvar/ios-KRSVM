Pod::Spec.new do |s|
  s.name         = "KRSVM"
  s.version      = "1.0.0"
  s.summary      = "KRSVM is implemented SVM of machine learning."
  s.description  = <<-DESC
                   KRSVM is implemented Support Vector Machine.
                   DESC
  s.homepage     = "https://github.com/Kalvar/ios-KRSVM"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Kalvar Lin" => "ilovekalvar@gmail.com" }
  s.social_media_url = "https://twitter.com/ilovekalvar"
  s.source       = { :git => "https://github.com/Kalvar/ios-KRSVM.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.public_header_files = 'SVM/*.h'
  s.source_files = 'SVM/*.{h,m}'
  s.frameworks   = 'Foundation'
end 