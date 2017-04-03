module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def show
        @deploy_keys = DeployKeysPresenter.new(@project, current_user: current_user)

        define_protected_refs
      end

      private

      def define_protected_refs
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
        @protected_tags = @project.protected_tags.order(:name).page(params[:page]) #TODO duplicated pagination param?
        @protected_branch = @project.protected_branches.new
        @protected_tag = @project.protected_tags.new
        load_gon_index
      end

      def access_levels_options
        #TODO: consider protected tags
        #TODO: Refactor ProtectedBranch::PushAccessLevel so it doesn't mention branches
        {
          push_access_levels: {
            roles: ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          },
          merge_access_levels: {
            roles: ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          }
        }
      end

      def protectable_tags_for_dropdown
        { open_tags: ProtectableDropdown.new(@project, :tags).hash }
      end

      def protectable_branches_for_dropdown
        { open_branches: ProtectableDropdown.new(@project, :branches).hash }
      end

      def load_gon_index
        gon.push(protectable_tags_for_dropdown)
        gon.push(protectable_branches_for_dropdown)
        gon.push(access_levels_options)
      end
    end
  end
end
