Pod::Spec.new do |s|
  s.name     = 'YubiKit'
  s.version  = '3.1.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'YubiKit is an iOS library provided by Yubico to interact with YubiKeys on iOS devices.'
  s.homepage = 'https://github.com/Yubico/yubikit-ios'
  s.author   = 'Yubico'
  s.source   = { :git => 'https://github.com/Yubico/yubikit-ios.git', :tag => s.version }
  s.requires_arc = true
  
  s.source_files = 'YubiKit/YubiKit/**/*.{h,m}'
  
  s.ios.deployment_target = '10.0'
end
