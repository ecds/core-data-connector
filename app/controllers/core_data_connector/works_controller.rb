module CoreDataConnector
  class WorksController < ApplicationController
    # Includes
    include MergeableController
    include NameableController
    include OwnableController
    include UserDefinedFields::Queryable

    # Preloads
    preloads :source_names, only: :show

    # Search attributes
    search_attributes :name
  end
end
