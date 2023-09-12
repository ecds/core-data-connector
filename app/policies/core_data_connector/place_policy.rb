module CoreDataConnector
  class PlacePolicy < BasePolicy
    include OwnablePolicy

    attr_reader :current_user, :place

    def initialize(current_user, place)
      @current_user = current_user
      @place = place
    end

    # Allowed create/update attributes.
    def permitted_attributes
      attrs = []
      attrs << ownable_attributes
      attrs << { place_names_attributes: [:id, :name, :primary, :_destroy] }
      attrs
    end

    protected

    def project_item
      place.project_item
    end

    # Include default ownable scope.
    class Scope < BaseScope
      include OwnableScope
    end
  end
end