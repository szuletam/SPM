class UserImport < ActiveRecord::Base
  include Redmine::SafeAttributes
  safe_attributes 'import_key', 'firstname', 'lastname', 'position_id', 'boss_id', 'username', 'direction_name', 'user_id', 'row_excel'

  def self.generate_key
    SecureRandom.urlsafe_base64(nil, false)
  end

  def self.get_errors
    @errors ||= {}
    @errors.sort_by{ |k,v| k }
  end

  def self.validate_import data
    @errors = {}
    token = save_data data
    if token
      validate_obligatory token, :firstname
      validate_obligatory token, :lastname
      validate_obligatory token, :position_id
      validate_obligatory token, :username
      validate_obligatory token, :direction_name
      validate_directions token
      validate_bosses token
      validate_positions token
    else
      add_error "Error al importar la información", 0
    end
    token
  end

  def self.clean_import token
    if token
      ActiveRecord::Base.connection.execute(
          "DELETE
           FROM #{UserImport.table_name}
           WHERE import_key = '#{token}'"
      )
    end
  end

  def self.validate_bosses token
    sql = "SELECT #{UserImport.table_name}.position_id
             FROM #{UserImport.table_name}
             WHERE #{UserImport.table_name}.position_id IS NOT NULL
                   AND #{UserImport.table_name}.position_id != ''
                   AND #{UserImport.table_name}.import_key = '#{token}'
             UNION
             SELECT position_id
             FROM #{User.table_name}
             WHERE position_id IS NOT NULL AND position_id != ''
              AND #{User.table_name}.login COLLATE utf8_unicode_ci NOT IN (
               SELECT username
               FROM #{UserImport.table_name}
               WHERE username IS NOT NULL
                     AND username != ''
                     AND #{UserImport.table_name}.import_key = '#{token}')"

    uis = UserImport.where(:import_key => token)
              .where("#{UserImport.table_name}.boss_id NOT IN (#{sql})")
              .where("#{UserImport.table_name}.boss_id IS NOT NULL")
              .where("#{UserImport.table_name}.boss_id != ''")
    uis.each do |ui|
      add_error "boss_id no existe como position_id", ui.row_excel
    end

  end

  def self.validate_positions token
    sql = "
      SELECT position_id
      FROM (
             SELECT #{UserImport.table_name}.position_id
             FROM #{UserImport.table_name}
             WHERE #{UserImport.table_name}.position_id IS NOT NULL
                   AND #{UserImport.table_name}.position_id != ''
                   AND #{UserImport.table_name}.import_key = '#{token}'
             UNION
             SELECT position_id
             FROM #{User.table_name}
             WHERE #{User.table_name}.login COLLATE utf8_unicode_ci NOT IN (
               SELECT username
               FROM #{UserImport.table_name}
               WHERE username IS NOT NULL
                     AND username != ''
                     AND #{UserImport.table_name}.import_key = '#{token}'
             )) t
      GROUP BY position_id
      HAVING COUNT(position_id) > 1"
    uis = UserImport.where(:import_key => token).where("#{UserImport.table_name}.position_id IN (#{sql})")
    uis.each do |ui|
      add_error "position_id duplicado", ui.row_excel
    end
  end

  def self.validate_directions token
    uis = UserImport.where(:import_key => token).where("#{Direction.table_name}.id" => [nil, ''])
              .joins(" LEFT JOIN #{Direction.table_name} ON (#{Direction.table_name}.name = #{UserImport.table_name}.direction_name COLLATE utf8_unicode_ci)")
    uis.each do |ui|
      add_error "la direccion especificada no existe", ui.row_excel
    end
  end

  def self.merge_data token
    UserImport.where(:import_key => token).each do |ui|
      user = User.find_by_login(ui.username)
      unless user
        user = User.new
        user.login = ui.username.downcase
      end
      user.firstname = ui.firstname
      user.lastname = ui.lastname
      user.position_id = ui.position_id
      user.boss_id = ui.boss_id
      user.direction = Direction.find_by_name(ui.direction_name)

      if user.new_record?
        user.auth_source_id = 1
        user.mail = "#{ui.username}@renault.com" unless user.mail
      end

      user.save
    end
  end

  def self.add_error error, row
    @errors ||= {}
    @errors[row] ||= []
    @errors[row] << error
  end

  def self.validate_obligatory token, field
    uis = UserImport.where(:import_key => token).where(field => [nil, ''])
    uis.each do |ui|
      add_error "#{field} no puede estar vacío", ui.row_excel
    end
  end

  def self.save_data data
    token = generate_key
    data.each do |position, row|
      begin
        ui = UserImport.new
        ui.firstname = row['firstname']
        ui.lastname = row['lastname']
        ui.position_id = row['position_id']
        ui.boss_id = row['boss_id']
        ui.direction_name = row['direction_name']
        ui.row_excel = row['row_excel']
        ui.username = row['username']
        ui.import_key = token
        ui.save
      rescue Exception => e
        return false
      end
    end
    token
  end

end
