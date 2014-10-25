require 'unitable'

module ActiveRecord
  module Type
    class Meter < Value
      include Mutable

      def type
        :meter
      end
      
      def type_cast_from_user(value)
        Unit::Meter.new(value)
      end

      def type_cast_from_database(value)
        return nil unless value.present?
        Unit::Meter.new(value)
      end

      def type_cast_for_database(value)
        value ? value.to_i : nil
      end
    end
  end
end

