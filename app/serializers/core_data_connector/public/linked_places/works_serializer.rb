module CoreDataConnector
  module Public
    module LinkedPlaces
      class WorksSerializer < Base
        include TypeableSerializer

        annotation_attributes(:id) { |work| "#{base_url}/works/#{work.uuid}" }
        annotation_attributes(:record_id) { |work| work.id }
        annotation_attributes(:title) { |work| work.primary_name&.name&.name }
        annotation_attributes(:type) { 'Work' }
        annotation_attributes :uuid, user_defined: UserDefinedSerializer
      end
    end
  end
end