#
# Be sure to run `pod lib lint SectionKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SectionKit'
  s.version          = '0.1.2'
  s.summary          = 'A modular fabric for interface. Based on UICollectionView, divided into sections'

  s.description      = <<-DESC
  Split your interface into sections with independent logic.
  
  Just initialize SectionsAdapter with your UICollectionView and set dataSource for sections
  A section should adopt specific interface - SectionPresentable
  
  Any section can by used on any screen with SectionKit.
                       DESC

  s.homepage         = 'https://github.com/konshin/SectionKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'konshin' => 'alexey@konshin.net' }
  s.source           = { :git => 'https://github.com/konshin/SectionKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.swift_versions = '5.1'

  s.source_files = 'SectionKit/Classes/**/*'
  
   s.frameworks = 'UIKit'
   s.dependency 'UICollectionUpdates', '~> 0.1.3'
end
