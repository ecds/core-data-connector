module CoreDataConnector
  module ImportAnalyze
    module Place
      extend ActiveSupport::Concern

      # Includes
      include Base

      class_methods do
        def base_query
          joins(:primary_name)
        end

        def group_by_columns
          [:name]
        end
      end
    end
  end
end