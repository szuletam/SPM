class ChecklistsController < ApplicationController

  before_filter :find_checklist_item, :except => [:index, :create]
  before_filter :find_issue_by_id, :only => [:index, :create]
  before_filter :authorize, :except => [:done]
  helper :issues

  accept_api_auth :index, :update, :destroy, :create, :show

  def index
    @checklists = @issue.checklists
    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def destroy
    @checklist_item.destroy
    respond_to do |format|
      format.api {render_api_ok}
    end
  end

  def create
    @checklist_item = Checklist.new(params[:checklist])
    @checklist_item.issue = @issue
    respond_to do |format|
      format.api {
        if @checklist_item.save
		  
          render :action => 'show', :status => :created, :location => checklist_url(@checklist_item)
        else
          render_validation_errors(@checklist_item)
        end
      }
    end
  end

  def update
    respond_to do |format|
      format.api {
        if @checklist_item.update_attributes(params[:checklist])
          render_api_ok
        else
          render_validation_errors(@checklist_item)
        end
      }
    end
  end

  def done
    (render_403; return false) unless User.current.allowed_to?(:done_checklists, @checklist_item.issue.project)
    old_checklist_item = @checklist_item.dup
	
	@checklist_item.is_done = params[:is_done] == 'true'

    if @checklist_item.save
      if old_checklist_item.info != @checklist_item.info
        journal = Journal.new(:journalized => @checklist_item.issue, :user => User.current)
        journal.details << JournalDetail.new(:property => 'attr',
                                              :prop_key => 'checklist',
                                              :old_value => old_checklist_item.info,
                                              :value => @checklist_item.info)
        journal.save
      end
	end
	
	@checklist_item.update_column(:is_done, params[:is_done] == 'true')
	
    respond_to do |format|
      format.js
      format.html { redirect_to :back }
    end
  end

  private

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_checklist_item
    @checklist_item = Checklist.find(params[:id])
    @project = @checklist_item.issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
