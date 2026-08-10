#!/usr/bin/env ruby
# One-off script that adds the NutritionWidgets WidgetKit extension target to
# Runner.xcodeproj — the CLI equivalent of Xcode's File > New > Target >
# Widget Extension wizard, since there is no interactive Xcode GUI here.
# Safe to re-run: it removes any previous NutritionWidgets target first.
require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner_target

# ── Clean up a previous run ────────────────────────────────────────────────
if (existing = project.targets.find { |t| t.name == 'NutritionWidgets' })
  runner_target.dependencies.delete_if { |d| d.target == existing }
  runner_target.build_phases.each do |phase|
    next unless phase.respond_to?(:files)
    phase.files.each { |f| phase.remove_build_file(f) if f.file_ref && f.file_ref.path.to_s.include?('NutritionWidgets') }
  end
  existing.remove_from_project
end
project.groups.each do |g|
  g.children.delete_if { |c| c.display_name == 'NutritionWidgets' && c.isa == 'PBXGroup' }
end

# ── Group + file references ────────────────────────────────────────────────
group = project.main_group.new_group('NutritionWidgets', 'NutritionWidgets')
swift_names = %w[Shared.swift MomentumWidget.swift TodayWidget.swift NutritionWidgetsBundle.swift ForkThisMomentWidget.swift]
swift_refs = swift_names.map { |name| group.new_reference(name) }
info_plist_ref = group.new_reference('Info.plist')
entitlements_ref = group.new_reference('NutritionWidgets.entitlements')

# ── Target ──────────────────────────────────────────────────────────────────
widget_target = project.new_target(
  :app_extension,
  'NutritionWidgets',
  :ios,
  '17.0'
)

swift_refs.each { |ref| widget_target.source_build_phase.add_file_reference(ref) }
widget_target.resources_build_phase # ensure it exists

frameworks_phase = widget_target.frameworks_build_phase
%w[WidgetKit SwiftUI].each do |fw|
  fw_ref = project.frameworks_group.new_reference("System/Library/Frameworks/#{fw}.framework")
  fw_ref.source_tree = 'SDKROOT'
  frameworks_phase.add_file_reference(fw_ref)
end

bundle_id = 'com.nutritionplatform.nutritionPlatform.NutritionWidgets'
widget_target.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_NAME' => 'NutritionWidgets',
    'PRODUCT_BUNDLE_IDENTIFIER' => bundle_id,
    'INFOPLIST_FILE' => 'NutritionWidgets/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'NutritionWidgets/NutritionWidgets.entitlements',
    'CODE_SIGN_STYLE' => 'Automatic',
    'CURRENT_PROJECT_VERSION' => '1',
    'MARKETING_VERSION' => '0.1.0',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'],
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => '',
    'DEVELOPMENT_TEAM' => ''
  )
end

# ── Embed into Runner + target dependency ──────────────────────────────────
embed_phase = runner_target.new_copy_files_build_phase('Embed Foundation Extensions')
embed_phase.symbol_dst_subfolder_spec = :plug_ins
embed_product_ref = widget_target.product_reference
build_file = embed_phase.add_file_reference(embed_product_ref)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeaderOnCopy'] }

runner_target.add_dependency(widget_target)

# Runner needs its own App Group entitlement to share data with the widget.
runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

project.save
puts "Added NutritionWidgets target (#{bundle_id}) and embedded it into Runner."
