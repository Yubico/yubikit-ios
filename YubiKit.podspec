Pod::Spec.new do |s|
  s.name     = 'YubiKit'
  s.version  = '4.7.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'YubiKit is an iOS library provided by Yubico to interact with YubiKeys on iOS devices.'
  s.homepage = 'https://github.com/Yubico/yubikit-ios'
  s.author   = 'Yubico'
  s.source   = { :git => 'https://github.com/Yubico/yubikit-ios.git', :tag => s.version }
  s.requires_arc = true

  s.source_files = 'YubiKit/YubiKit/**/*.{h,m}'
  s.exclude_files = 'YubiKit/YubiKit/SPMHeaderLinks/*'

  s.ios.deployment_target = '11.0'
  s.weak_framework = 'CoreNFC'
end
