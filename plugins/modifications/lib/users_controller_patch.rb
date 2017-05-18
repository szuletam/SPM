module UsersControllerPatch
	def self.included(base) # :nodoc:
		base.send(:include, InstanceMethods)
		base.class_eval do
			alias_method_chain :create, :modification
			alias_method_chain :show, :modification
			alias_method_chain :update, :modification
		end
	end
	module InstanceMethods
		def show_with_modification

			unless @user.visible?
				render_404
				return
			end

			# show projects based on current user visibility
			@memberships = @user.memberships.where(Project.visible_condition(User.current)).to_a
			projects_tree = Project.project_tree(@memberships.map{|m| m.project}){|p| p}
			@memberships = @memberships.sort_by do |m|
				projects_tree.index(m.project)
			end

			respond_to do |format|
				format.html {
					events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil,:limit => 10)
					@events_by_day = events.group_by(&:event_date)
					render :layout => 'base'
				}
				format.api
			end
		end

		def create_with_modification
			@user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
			@user.safe_attributes = params[:user]
			@user.admin = params[:user][:admin] || false
			@user.director = params[:user][:director] || false
			@user.general = params[:user][:general] || false
			@user.login = params[:user][:login]
			@user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id
			@user.pref.attributes = params[:pref] if params[:pref]

			if @user.save
				Mailer.account_information(@user, @user.password).deliver if params[:send_information]

				respond_to do |format|
					format.html {
						flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user)))
						if params[:continue]
							attrs = params[:user].slice(:generate_password)
							redirect_to new_user_path(:user => attrs)
						else
							redirect_to edit_user_path(@user)
						end
					}
					format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
				end
			else
				@auth_sources = AuthSource.all
				# Clear password input
				@user.password = @user.password_confirmation = nil

				respond_to do |format|
					format.html { render :action => 'new' }
					format.api  { render_validation_errors(@user) }
				end
			end
		end

		def update_with_modification
			@user.admin = params[:user][:admin] if params[:user][:admin]
			@user.director = params[:user][:director] if params[:user][:admin]
			@user.general = params[:user][:general] if params[:user][:general]
			@user.login = params[:user][:login] if params[:user][:login]
			if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
				@user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
			end
			@user.safe_attributes = params[:user]
			# Was the account actived ? (do it before User#save clears the change)
			was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
			# TODO: Similar to My#account
			@user.pref.attributes = params[:pref] if params[:pref]

			if @user.save
				@user.pref.save

				if was_activated
					Mailer.account_activated(@user).deliver
				elsif @user.active? && params[:send_information] && @user.password.present? && @user.auth_source_id.nil? && @user != User.current
					Mailer.account_information(@user, @user.password).deliver
				end

				respond_to do |format|
					format.html {
						flash[:notice] = l(:notice_successful_update)
						redirect_to_referer_or edit_user_path(@user)
					}
					format.api  { render_api_ok }
				end
			else
				@auth_sources = AuthSource.all
				@membership ||= Member.new
				# Clear password input
				@user.password = @user.password_confirmation = nil

				respond_to do |format|
					format.html { render :action => :edit }
					format.api  { render_validation_errors(@user) }
				end
			end
		end
	end
end
