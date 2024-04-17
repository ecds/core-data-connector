module CoreDataConnector
  class EventsController < ApplicationController
    # Includes
    include OwnableController
    include UserDefinedFields::Queryable

    # Preloads
    preloads :start_date, :end_date

    # Joins
    joins Event.start_date_join, Event.end_date_join

    # Search attributes
    search_attributes :name, :description
  end
end