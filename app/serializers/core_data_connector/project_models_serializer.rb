module CoreDataConnector
  class ProjectModelsSerializer < BaseSerializer
    # Includes
    include UserDefinedFields::DefineableSerializer

    index_attributes :id, :project_id, :name, :model_class, :model_class_view
    show_attributes :id, :project_id, :name, :model_class
  end
end