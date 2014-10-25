module PostgresqlTypes
  class Railtie < Rails::Railtie
    initializer "postgresql-types.configure_rails_initialization" do
      ActiveSupport.on_load(:active_record) do
        require "#{File.dirname(__FILE__)}/type_map_initializer"
        
        ActiveRecord::Base.connection.load_custom_database_types
      end
    end
  end
end


        
# def native_database_types
#   @additional_db_types ||= {
#     geography:  {name: 'geography'}, 
#     geometry:   {name: 'geometry'},
#   }.merge(NATIVE_DATABASE_TYPES)
# end
