Pod::Spec.new do |s|
  s.name             = 'hybrid_location'
  s.version          = '0.1.0'
  s.summary          = 'Get device location using Wi-Fi, cell towers, IP, or BLE — no GPS required.'
  s.description      = <<-DESC
    A Flutter plugin that determines device location without GPS by falling back
    across Wi-Fi access points, cell towers, IP geolocation, and BLE beacons.
  DESC
  s.homepage         = 'https://github.com/yourname/hybrid_location'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'you@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
