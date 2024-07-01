module CoreDataConnector
  class ProjectsController < ApplicationController
    # Search attributes
    search_attributes :name

    def clear
      project = Project.find(params[:id])
      authorize project, :clear?

      # Query for models that are not shared with other projects
      project_models = ProjectModel
                         .unshared
                         .where(project_id: project.id)

      begin
        project_models.map(&:clear)
      rescue StandardError => exception
        errors = [exception]
      end

      if errors.nil? || errors.empty?
        render json: { }, status: :ok
      else
        render json: { errors: errors }, status: :bad_request
      end
    end

    def export_configuration
      project = Project.find(params[:id])
      authorize project, :export_configuration?

      options = load_records(project)
      serializer = ProjectConfigurationsSerializer.new(current_user, options)

      json = { param_name.to_sym => serializer.render_show(project) }
      render json: json, status: :ok
    end

    def export_data
      project = Project.find(params[:id])
      authorize project, :export_data?

      begin
        directory = FileSystem.create_directory
        filename = "#{project.name.gsub(/\s+/, "")}.zip"

        # Run the exporter to generate the CSV files
        exporter = Export::Exporter.new(project.id)
        exporter.run(directory)

        # Create a zip file of the CSVs in the passed directory
        FileSystem.create_zip directory, filename

        # Send the file to the client
        zip = File.join(directory, filename)

        File.open(zip, 'r') do |file|
          send_data file.read, filename: filename, type: 'application/zip', disposition: 'attachment'
        end
      rescue StandardError => exception
        # Render a 400 response if an errors occur
        render json: { errors: [exception] }, status: :bad_request
      ensure
        # Remove the temporary directory
        FileSystem.remove_directory directory
      end
    end

    def export_variables
      project = Project.find(params[:id])
      authorize project, :export_variables?

      serializer = ProjectVariablesSerializer.new(current_user)

      json = { param_name.to_sym => serializer.render_show(project) }
      render json: json, status: :ok
    end

    def import_configuration
      render json: { errors: [I18n.t('errors.projects.import_configuration')] }, status: :bad_request and return unless params[:file].present?

      project = Project.find(params[:id])
      authorize project, :import_configuration?

      begin
        service = Configuration.new(project, params[:file])
        service.import_configuration
      rescue StandardError => exception
        errors = [exception]
      end

      if errors.nil? || errors.empty?
        render json: { }, status: :ok
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end

    def import_data
      render json: { errors: [I18n.t('errors.projects.import_data')] }, status: :bad_request and return unless params[:file].present?

      project = Project.find(params[:id])
      authorize project, :import_data?

      zip_importer = Import::ZipHelper.new
      ok, errors = zip_importer.import_zip(params[:file].tempfile)

      if errors.nil? || errors.empty?
        render json: { }, status: :ok
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end

    protected

    # If we're not looking for "discoverable" projects, use base query defined by the policy. Otherwise, return
    # a query to find all discoverable projects not matching the current project.
    def base_query
      return super unless params[:discoverable].to_s.to_bool && params[:project_id].present?

      Project
        .where(discoverable: true)
        .where.not(id: params[:project_id])
    end

    # Automatically add the user who created the project as the owner, if they are not an admin.
    def after_create(project)
      return if current_user.admin?

      UserProject.create(
        project_id: project.id,
        user_id: current_user.id,
        role: UserProject::ROLE_OWNER
      )
    end
  end
end