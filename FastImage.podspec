#
# Be sure to run `pod lib lint KHIFastImage.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "FastImage"
  s.version          = "2.0.0"
  s.summary          = "Get a remote images size and type by downloading the first few batches of data."
  s.description      = <<-DESC
                       FastImage is an Objective-C port of the Ruby project by Stephen Sykes. It's directive is too request as little data as possible (usually just the first batch of bytes returned by a request), to determine the size and type of a remote image.
                       DESC
  s.homepage         = "https://github.com/kylehickinson/FastImage"
  s.license          = 'MIT'
  s.author           = { "Kyle Hickinson" => "git@kylehickinson.com" }
  s.source           = { :git => "https://github.com/kylehickinson/FastImage.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'FastImage'
  s.public_header_files = 'FastImage/**/*.h'
  s.frameworks = 'Foundation', 'CoreGraphics'
end
