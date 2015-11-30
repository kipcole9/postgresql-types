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
          # Create enums
          if ActiveRecord::Base.connection.enum_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
            
          # Create composite type
          elsif ActiveRecord::Base.connection.composite_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
            
          # Create domain type
          elsif ActiveRecord::Base.connection.domain_type_exists? method.to_s
            options = args.extract_options!
            column(args[0], method.to_s, options)
          
          # Back to normal flow
          else
            super
          end
        end
      end
    end
  end
end


# module ActiveRecord
#   module ConnectionAdapters
#     # PostgreSQL-specific extensions to column definitions in a table.
#     class PostgreSQLColumn < Column #:nodoc:
#
#       # Extracts the value from a PostgreSQL column default definition.
#       def self.extract_value_from_default(default)
#         # Also extract default from user_defined enums
#         return default unless default
#
#         case default
#           when /\A'(.*)'::(num|date|tstz|ts|int4|int8)range\z/m
#             $1
#           # Numeric types
#           when /\A\(?(-?\d+(\.\d*)?\)?(::bigint)?)\z/
#             $1
#           # Character types
#           when /\A\(?'(.*)'::.*\b(?:character varying|bpchar|text)\z/m
#             $1
#           # Binary data types
#           when /\A'(.*)'::bytea\z/m
#             $1
#           # Date/time types
#           when /\A'(.+)'::(?:time(?:stamp)? with(?:out)? time zone|date)\z/
#             $1
#           when /\A'(.*)'::interval\z/
#             $1
#           # Boolean type
#           when 'true'
#             true
#           when 'false'
#             false
#           # Geometric types
#           when /\A'(.*)'::(?:point|line|lseg|box|"?path"?|polygon|circle)\z/
#             $1
#           # Network address types
#           when /\A'(.*)'::(?:cidr|inet|macaddr)\z/
#             $1
#           # Bit string types
#           when /\AB'(.*)'::"?bit(?: varying)?"?\z/
#             $1
#           # XML type
#           when /\A'(.*)'::xml\z/m
#             $1
#           # Arrays
#           when /\A'(.*)'::"?\D+"?\[\]\z/
#             $1
#           # Hstore
#           when /\A'(.*)'::hstore\z/
#             $1
#           # JSON
#           when /\A'(.*)'::json\z/
#             $1
#           # Object identifier types
#           when /\A-?\d+\z/
#             $1
#           else
#             if ActiveRecord::Base.connection.enum_types.include? default.match(/\'(.*)\'::(.*)/).try(:[],2)
#               $1
#             else
#               # Anything else is blank, some user type, or some function
#               # and we can't know the value of that, so return nil.
#               nil
#             end
#         end
#       end
#     end
#   end
# end
