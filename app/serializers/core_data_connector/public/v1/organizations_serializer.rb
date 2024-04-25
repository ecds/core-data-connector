module CoreDataConnector
  module Public
    module V1
      class OrganizationsSerializer < PublicSerializer
        include TypeableSerializer
        include UserDefineableSerializer

        index_attributes :uuid, :name
        show_attributes :uuid, :name, :description, organization_names: [:id, :name, :primary]
      end
    end
  end
end