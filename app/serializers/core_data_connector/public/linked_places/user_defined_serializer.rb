module CoreDataConnector
  module Public
    module LinkedPlaces
      class UserDefinedSerializer < BaseSerializer
        def render_index(item)
          serialized = {}

          # Retrieve all of the user-defined fields on the passed item
          render_user_defined item, options[:user_defined_fields], serialized

          # Only render relationships for an annotation route
          return serialized unless options[:target].present?

          # Retrieve all of the user-defined fields on the relationships for the passed item
          item.relationships.each do |relationship|
            user_defined_fields = relationship.project_model_relationship.user_defined_fields
            render_user_defined relationship, user_defined_fields, serialized
          end

          # Retrieve all of the user-defined fields on the related relationships for the passed item
          item.related_relationships.each do |relationship|
            user_defined_fields = relationship.project_model_relationship.user_defined_fields
            render_user_defined relationship, user_defined_fields, serialized
          end

          serialized
        end

        private

        def render_user_defined(item, fields, hash)
          return if fields.nil?

          fields.each do |field|
            value = item.user_defined[field.uuid]
            next if value.nil?

            hash[field.uuid] = {
              label: field.column_name,
              value: value
            }
          end
        end
      end
    end
  end
end