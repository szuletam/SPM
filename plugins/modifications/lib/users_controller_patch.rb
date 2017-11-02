require 'roo'
require 'rest_client'
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
		def import
		end

		#****************
		USERNAME = "admin" # needed to access the APi
		PASSWORD = "Admin2017$%" # needed to access the APi
		API_BASE_URL = "https://www.renaulthome.com/APISofasa/api" # base url of the API
		#****************

		def import_positions

			uri = "#{API_BASE_URL}/login" # specifying json format in the URl
			rest_resource = RestClient::Request.execute(method: :post, url: uri, headers: {params: {username: USERNAME, password: PASSWORD}}, :content_type => 'application/x-www-form-urlencoded', :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
			api_params = JSON.parse(rest_resource, :symbolize_names => true)
      api_params[:take] = 3000 # Nro de usuarios que devolverá la consulta
			uri = "#{API_BASE_URL}/employees" # specifying json format in the URl
      employees = RestClient::Request.execute(method: :get, url: uri, headers: {params: api_params}, :content_type => 'application/x-www-form-urlencoded', :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
      empl_array = JSON.parse(employees)

			data = {}
      empl_array['data'].each do |u|
				unless u['userName'].empty?
					data[u['position_id']] = u
				end
      end

			token = UserImport.validate_import(data)
			@errors = UserImport.get_errors
      @user_number = (data.length - @errors.length)
			UserImport.merge_data(token)
			UserImport.clean_import token

      # Envía notificación de errores
			user = User.find_by_login('admin')
			Mailer.notification_bpu_sync(user, @errors, @user_number).deliver

		end

			def open_spreadsheet(file)
				case File.extname(file.original_filename)
					when ".csv" then Csv.new(file.path, nil, :ignore)
					when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
					when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
					else raise "Unknown file type: #{file.original_filename}"
				end
			end

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
