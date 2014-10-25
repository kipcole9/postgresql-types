module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      def reload_type_map
        super
        load_custom_database_types
      end

      def load_custom_database_types
        ActiveRecord::Base.connection.tap do |conn|
          conn.type_map.register_type 'meter',      ::ActiveRecord::Type::Meter.new
          conn.type_map.register_type 'currency',   ::ActiveRecord::Type::Currency.new
          conn.type_map.register_type 'geometry',   ::ActiveRecord::Type::Geometry.new
          conn.type_map.register_type 'geography',  ::ActiveRecord::Type::Geography.new
          conn.type_map.alias_type    'regclass',   :varchar
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class TypeMapInitializer
          private

          # If we are planning to manage the type on our own (as evidenced by 
          # the existence of an ActiveRecord::Type manager) then don't override
          def register_domain_type(row)
            return if defined?("ActiveRecord::Type::#{row['typname'].capitalize}".constantize)
            if base_type = @store.lookup(row["typbasetype"].to_i)
              register row['oid'], base_type
            else
              warn "unknown base type (OID: #{row["typbasetype"]}) for domain #{row["typname"]}."
            end
          end
        end
      end
    end
  end
end