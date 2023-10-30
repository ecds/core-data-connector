module CoreDataConnector
  class ProjectModelPolicy < BasePolicy
    attr_reader :current_user, :project_model

    def initialize(current_user, project_model)
      @current_user = current_user
      @project_model = project_model
    end

    # A user can create project models if they are the owner of the project.
    def create?
      return true if current_user.admin?

      owner?
    end

    # A user can delete project models if they are the owner of the project.
    def destroy?
      return true if current_user.admin?

      owner?
    end

    # A user can view project models if they are the owner of the project.
    def show?
      return true if current_user.admin?

      member?
    end

    # A user can update project models if they are the owner of the project.
    def update?
      return true if current_user.admin?

      owner?
    end

    def permitted_attributes
      [:project_id, :name, :model_class, :slug, *ProjectModel.permitted_params,
       project_model_relationships_attributes: [:id, :primary_model_id, :related_model_id, :name, :multiple, :slug,
                                                :allow_inverse, :inverse_name, :inverse_multiple, :_destroy,
                                                *ProjectModelRelationship.permitted_params],
       inverse_project_model_relationships_attributes: [:id, :primary_model_id, :related_model_id, :name, :multiple, :slug,
                                                :allow_inverse, :inverse_name, :inverse_multiple, :_destroy,
                                                *ProjectModelRelationship.permitted_params]]
    end

    private

    # Returns true if the current user has a `user_projects` record for the model's project.
    def member?
      current_user
        .user_projects
        .where(project_id: project_model.project_id)
        .exists?
    end

    # Returns true if the current user has an owner `user_projects` record for the model's project.
    def owner?
      current_user
        .user_projects
        .where(project_id: project_model.project_id)
        .where(role: UserProject::ROLE_OWNER)
        .exists?
    end

    # A user can view project models for any project they own.
    class Scope < BaseScope
      def resolve
        return scope.all if current_user.admin?

        scope.where(
          UserProject
            .where(UserProject.arel_table[:project_id].eq(ProjectModel.arel_table[:project_id]))
            .where(user_id: current_user.id)
            .where(role: UserProject::ROLE_OWNER)
            .arel
            .exists
        )
      end
    end
  end
end