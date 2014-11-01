# Handle methods which represent user created enum, composite and domain types and geo types
module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class TableDefinition
        def geometry(name, options = {})
          if ActiveRecord::Base.connection.extensions.include? 'postgis'
            column(name, 'geometry', options)
          else
            point(name, options)
          end
        end
      
        def geography(name, options = {})
          if ActiveRecord::Base.connection.extensions.include? 'postgis'
            column(name, 'geography', options)
          else
            point(name, options)
          end             
        end
        
        def method_missing(method, *args, &block)
          if ActiveRecord::Base.connection.enum_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
          elsif ActiveRecord::Base.connection.composite_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
          elsif ActiveRecord::Base.connection.domain_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
          else
            super
          end
        end
      end
    end
  end
end

# Enable extensions in a given SCHEMA either supplied or
# defined in database configuration
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter 
      def enable_extension(name, options = {})
        schema = options[:schema] || Rails.configuration.database_configuration[Rails.env]['extensions_schema']
        exec_query("CREATE EXTENSION IF NOT EXISTS \"#{name}\" #{' SCHEMA ' + schema if schema}").tap {
          reload_type_map
        }
      end
      
      def clear_cache_for_search_path!(search_path)
        @statements.clear_for_search_path(search_path)
      end
      
      def prepare_column_options(column, types)
        spec = {}
        spec[:name]      = column.name.inspect
        spec[:type]      = column.type.to_s
        spec[:limit]     = column.limit.inspect if types[column.type] && column.limit != types[column.type][:limit]
        spec[:precision] = column.precision.inspect if column.precision
        spec[:scale]     = column.scale.inspect if column.scale
        spec[:null]      = 'false' unless column.null
        spec[:default]   = schema_default(column) if column.has_default?
        spec.delete(:default) if spec[:default].nil?
        spec[:array] = 'true' if column.respond_to?(:array) && column.array
        spec[:default] = "\"#{column.default_function}\"" if column.default_function
        sql_type_without_schema = column.sql_type.split('.').last
        if enum_types.include?(sql_type_without_schema) || composite_types.include?(sql_type_without_schema) || domain_types.include?(sql_type_without_schema)
          spec[:type] = sql_type_without_schema 
          spec.delete(:limit)
        end
        spec
      end
      
      class StatementPool < ConnectionAdapters::StatementPool
        def clear_for_search_path(search_path)
          cache.each_key do |key|
            path_key = key.split('-').first
            if path_key.gsub(' ','') == search_path.gsub(' ','')
              # puts "Deleting statement cache entry #{key}"
              delete(key)
            else
              puts "SHOULD HAVE DELETED #{path_key} given #{search_path}" if path_key =~ /test/
            end 
          end
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      class ColumnDefinition < ActiveRecord::ConnectionAdapters::ColumnDefinition
        attr_accessor :array
      end
      
      class TableDefinition
        def column(name, type = nil, options = {})
          super
          column = self[name]
          column.array = options[:array]
          self
        end
      end
      
      class SchemaCreation < AbstractAdapter::SchemaCreation
        private
        
        # Modified because the table name may be schema.table_name
        def visit_TableDefinition(o)
          create_sql = "CREATE#{' TEMPORARY' if o.temporary} TABLE "
          create_sql << "#{quote_table_name(o.name)} ("
          create_sql << o.columns.map { |c| accept c }.join(', ')
          create_sql << ") #{o.options}"
          create_sql
        end
        
        # Modified so allow specification of pk sequence        
        def visit_ColumnDefinition(o)
          sql = super
          if o.primary_key? && o.type == :uuid
            sql << " PRIMARY KEY "
            add_column_options!(sql, column_options(o))
          end
          sql
        end
      end
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    # PostgreSQL-specific extensions to column definitions in a table.
    class PostgreSQLColumn < Column #:nodoc:

      # Extracts the value from a PostgreSQL column default definition.
      def self.extract_value_from_default(default)
        # Also extract default from user_defined enums
        return default unless default

        case default
          when /\A'(.*)'::(num|date|tstz|ts|int4|int8)range\z/m
            $1
          # Numeric types
          when /\A\(?(-?\d+(\.\d*)?\)?(::bigint)?)\z/
            $1
          # Character types
          when /\A\(?'(.*)'::.*\b(?:character varying|bpchar|text)\z/m
            $1
          # Binary data types
          when /\A'(.*)'::bytea\z/m
            $1
          # Date/time types
          when /\A'(.+)'::(?:time(?:stamp)? with(?:out)? time zone|date)\z/
            $1
          when /\A'(.*)'::interval\z/
            $1
          # Boolean type
          when 'true'
            true
          when 'false'
            false
          # Geometric types
          when /\A'(.*)'::(?:point|line|lseg|box|"?path"?|polygon|circle)\z/
            $1
          # Network address types
          when /\A'(.*)'::(?:cidr|inet|macaddr)\z/
            $1
          # Bit string types
          when /\AB'(.*)'::"?bit(?: varying)?"?\z/
            $1
          # XML type
          when /\A'(.*)'::xml\z/m
            $1
          # Arrays
          when /\A'(.*)'::"?\D+"?\[\]\z/
            $1
          # Hstore
          when /\A'(.*)'::hstore\z/
            $1
          # JSON
          when /\A'(.*)'::json\z/
            $1
          # Object identifier types
          when /\A-?\d+\z/
            $1
          else
            if ActiveRecord::Base.connection.enum_types.include? default.match(/\'(.*)\'::(.*)/).try(:[],2)
              $1
            else
              # Anything else is blank, some user type, or some function
              # and we can't know the value of that, so return nil.
              nil
            end
        end
      end
    end
  end
end
