class ProjectsController < ApplicationController
  before_action :set_active_nav
  before_action :check_dependencies, only: [:new]

  def index
    authorize! :read, Project

    state = params.fetch(:state, nil)
    scope = current_account.customers.includes(:projects).references(:projects)
    if state.present? && Project.states.include?(state.to_sym)
      scope = scope.where("projects.state = ?", state)
    else
      scope = scope.where("projects.state = ?", :active)
    end

    @customers = scope.order(sort_column + " " + sort_direction)
                 .page(params.fetch(:page, nil))
                 .per(20)
  end

  def show
    authorize! :read, project
  end

  def new
    authorize! :create, Project
    if customer
      @project = customer.projects.new
    else
      @project = Project.new
    end
  end

  def edit
    authorize! :update, project
  end

  def create
    authorize! :create, Project
    if project.save
      redirect_to projects_path, flash: { success: I18n.t(:"messages.project.create.success") }
    else
      flash.now[:alert] = I18n.t(:"messages.project.create.failure")
      render "new"
    end
  end

  def update
    authorize! :update, project
    if project.update_attributes(project_params)
      redirect_to projects_path, flash: { success: I18n.t(:"messages.project.update.success") }
    else
      flash.now[:alert] = I18n.t(:"messages.project.update.failure")
      render "edit"
    end
  end

  def unarchive
    authorize! :archive, project
    project.unarchive
    project.save
    if project.reload.active?
      redirect_to projects_path, flash: { success: I18n.t(:"messages.project.unarchive.success") }
    else
      redirect_to projects_path, alert: I18n.t(:"messages.project.unarchive.failure")
    end
  end

  private def sort_column
    (Project.column_names + %w(customers.name)).include?(params[:sort]) ? params[:sort] : "customers.name"
  end
  helper_method :sort_column

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "asc"
  end

  private def set_active_nav
    @active_nav = 'projects'
  end

  private def customers
    @customers ||= current_account.customers
  end
  helper_method :customers

  private def customer
    @customer ||= current_account.customers.where(id: params.fetch(:customer_uuid, nil)).first
  end

  private def project_params
    @project_params ||= params.require(:project).permit(
      :customer_id,
      :name,
      :rate,
      :budget,
      :budget_on_dashboard,
      tasks_attributes: [
        :id,
        :name,
        :project_id,
        :_destroy
      ]
    )
  end

  private def project
    @project ||= Project.where(id: params.fetch(:id, nil)).first
    @project ||= current_account.projects.new project_params
  end
  helper_method :project

  private def check_dependencies
    return if current_account.address.present?
    redirect_to "#{edit_account_path}#address", alert: I18n.t(:"messages.project.missing_address")
  end
end
