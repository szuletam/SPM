#Example:
#  rake redmine:update_project_indicators RAILS_ENV="production"
#END_DESC

require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")

class SyncBpu
	#****************
	USERNAME = "admin" # needed to access the APi
	PASSWORD = "Admin2017$%" # needed to access the APi
	API_BASE_URL = "https://www.renaulthome.com/APISofasa/api" # base url of the API
	#****************

  def sync_bpu
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
    Mailer.account_activated_cstm(user, @errors, @user_number).deliver
  end
end

namespace :redmine do
  task :sync_bpu_auto => :environment do
    task_obj = SyncBpu.new
	task_obj.sync_bpu
  end
end
