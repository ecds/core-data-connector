module CoreDataConnector
  module Search
    module Organization
      extend ActiveSupport::Concern

      class_methods do
        def preloads
          [:primary_name, :organization_names]
        end
      end

      included do
        # Includes
        include Base

        # Search attributes
        search_attribute :description

        search_attribute(:name) do
          primary_name.name
        end

        search_attribute(:names, facet: true) do
          organization_names.map(&:name)
        end
      end

    end
  end
end