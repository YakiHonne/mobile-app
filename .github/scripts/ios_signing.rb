require 'plist'
require 'xcodeproj'

tmp = ENV.fetch('RUNNER_TEMP')
profiles = {
  'Runner' => ['com.yakihonne.appyakihonne', Plist.parse_xml("#{tmp}/runner.plist")],
  'ShareExtension' => ['com.yakihonne.appyakihonne.ShareExtension', Plist.parse_xml("#{tmp}/share.plist")],
  'SafariHighlightExtension' => ['com.yakihonne.appyakihonne.SafariHighlightExtension', Plist.parse_xml("#{tmp}/safari.plist")]
}
project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
profiles.each do |target_name, (bundle_id, profile)|
  abort "Wrong profile for #{bundle_id}" unless profile.dig('Entitlements', 'application-identifier') == "JU5BUTKJC2.#{bundle_id}"
  target = project.targets.find { |item| item.name == target_name } or abort "Missing #{target_name} target"
  target.build_configurations.each do |config|
    next unless config.name == 'Release'
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profile.fetch('UUID')
    config.build_settings['DEVELOPMENT_TEAM'] = 'JU5BUTKJC2'
  end
end
project.save
options = {
  'method' => 'app-store-connect',
  'signingStyle' => 'manual',
  'teamID' => 'JU5BUTKJC2',
  'provisioningProfiles' => profiles.values.to_h { |bundle_id, profile| [bundle_id, profile.fetch('UUID')] }
}
File.write("#{tmp}/ExportOptions.plist", options.to_plist)
