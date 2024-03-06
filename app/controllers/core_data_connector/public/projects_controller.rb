module CoreDataConnector
  module Public
    class ProjectsController < ApplicationController
      include UnauthenticateableController

      def descriptors
        descriptors = []
        descriptors += load_project_models
        descriptors += load_project_model_relationships

        render json: { descriptors: descriptors}, status: :ok
      end

      private

      def load_project_model_relationships
        descriptors = []

        query = ProjectModelRelationship
                  .preload(:user_defined_fields, :primary_model)
                  .joins(:primary_model)
                  .where(primary_model: {
                    project_id: params[:id]
                  })

        query.find_each do |project_model_relationship|
          descriptors << {
            identifier: project_model_relationship.uuid,
            label: project_model_relationship.name,
            context: project_model_relationship.primary_model.name
          }

          project_model_relationship.user_defined_fields.each do |user_defined_field|
            descriptors << {
              identifier: user_defined_field.uuid,
              label: user_defined_field.column_name,
              context: project_model_relationship.name
            }
          end
        end

        descriptors
      end

      def load_project_models
        descriptors = []

        query = ProjectModel
                  .preload(:user_defined_fields)
                  .where(project_id: params[:id])

        query.find_each do |project_model|
          descriptors << {
            identifier: project_model.uuid,
            label: project_model.name
          }

          project_model.user_defined_fields.each do |user_defined_field|
            descriptors << {
              identifier: user_defined_field.uuid,
              label: user_defined_field.column_name,
              context: project_model.name
            }
          end
        end

          descriptors
      end
    end
  end
end