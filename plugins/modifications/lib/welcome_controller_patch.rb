module WelcomeControllerPatch    
  def self.included(base) # :nodoc:
	base.send(:include, InstanceMethods)          
	base.class_eval do    
	  alias_method_chain :index, :modification
    end
  end
  module InstanceMethods
    def index_with_modification
	  @news = News.latest User.current
	  @projects = Project.latest User.current
	end
  end
end
