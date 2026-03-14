require 'xcodeproj'

# Path to the actual .xcodeproj file
project_path = 'RehApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Main target (RehApp)
target = project.targets.first

# Helper to find or create group hierarchy
def ensure_group(project, path)
  current_group = project.main_group
  path.split('/').each do |component|
    next if component.empty?
    next_group = current_group.children.find { |c| c.display_name == component || c.path == component }
    current_group = next_group || current_group.new_group(component)
  end
  current_group
end

# 1. Add Resources/condromalacia_protocol.json
resources_group = ensure_group(project, 'RehApp/Resources')
json_path = 'RehApp/Resources/condromalacia_protocol.json'
json_ref = resources_group.new_reference(json_path)
target.resources_build_phase.add_file_reference(json_ref, true)
puts "Added #{json_path}"

# 2. Add Models/RecoveryProtocol.swift
models_group = ensure_group(project, 'RehApp/Models')
protocol_model_path = 'RehApp/Models/RecoveryProtocol.swift'
protocol_model_ref = models_group.new_reference(protocol_model_path)
target.source_build_phase.add_file_reference(protocol_model_ref, true)
puts "Added #{protocol_model_path}"

# 3. Add MLTraining Group and Model
ml_group = ensure_group(project, 'MLTraining')
mlmodel_path = '../MLTraining/RehabPhasePredictor.mlmodel'
mlmodel_ref = ml_group.new_reference(mlmodel_path)
target.source_build_phase.add_file_reference(mlmodel_ref, true)
puts "Added RehabPhasePredictor.mlmodel"

# Optional: Adding the script just as a reference (not compiling it in the app)
script_path = '../MLTraining/train_rehab_model.swift'
ml_group.new_reference(script_path)

# 4. Add Services (ProtocolService & PredictorService)
services_group = ensure_group(project, 'RehApp/Services')

predictor_service_path = 'RehApp/Services/RehabPhasePredictorService.swift'
predictor_service_ref = services_group.new_reference(predictor_service_path)
target.source_build_phase.add_file_reference(predictor_service_ref, true)
puts "Added #{predictor_service_path}"

protocol_service_path = 'RehApp/Services/ProtocolService.swift'
protocol_service_ref = services_group.new_reference(protocol_service_path)
target.source_build_phase.add_file_reference(protocol_service_ref, true)
puts "Added #{protocol_service_path}"

project.save
puts "Successfully saved project modifications."
