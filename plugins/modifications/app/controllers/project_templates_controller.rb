class ProjectTemplatesController < ApplicationController
  
  helper 'sort'
  
  include SortHelper
  
  before_filter :require_login, :only => [:index, :destroy]
  
  def index
    sort_init 'name', 'asc'
    sort_update %w(name created_on)

    @limit = per_page_option

    scope = ProjectTemplate
    scope = scope.like(params[:name]) if params[:name].present?

    @project_template_count = scope.count
    @project_template_pages = Paginator.new @project_template_count, @limit, params['page']
    @offset ||= @project_template_pages.offset
    @project_templates =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
    end
  end
  
  def destroy
	@project = ProjectTemplate.find(params[:id])
    @project.destroy
    respond_to do |format|
      format.html { redirect_to project_templates_path }
    end
  rescue
	 render_404
  end
  
end
