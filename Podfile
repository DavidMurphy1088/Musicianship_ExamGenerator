# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Musicianship_ExamGenerator' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftJWT'
  pod 'Alamofire'

  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
          target.build_configurations.each do |config|
              #config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
		config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
           end
      end
    end
  end

  # Pods for Musicianship_ExamGenerator

  target 'Musicianship_ExamGeneratorTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Musicianship_ExamGeneratorUITests' do
    # Pods for testing
  end

end
