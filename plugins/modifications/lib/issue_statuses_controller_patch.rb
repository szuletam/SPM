module IssueStatusesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :index, :modification
    end
  end
  module InstanceMethods
    def index_with_modification
      @issue_statuses = params["issue"] && Issue.exists?(params["issue"]) ?
          Issue.find(params["issue"]).new_statuses_allowed_to(User.current).select{|ie| !ie.is_closed?} : IssueStatus.sorted.to_a
      respond_to do |format|
        format.html { render :layout => false if request.xhr? }
        format.api
      end
    end
  end
end
