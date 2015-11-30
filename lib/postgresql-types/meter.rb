require 'unitable'

module ActiveRecord
  module Type
    class Meter < ActiveModel::Type::Value # :nodoc:
      include ActiveModel::Type::Helpers::Mutable

      def self.as_json(options = {})
        {
          properties: {
            meter: {
              type:         :number,
              description:  I18n.t("schema.property.meter")
            }
          }
        }
      end
      
      def type
        :meter
      end
      
      def cast(value)
        Unit::Meter.new(value)
      end

      def deserialize(value)
        return nil unless value.present?
        Unit::Meter.new(value)
      end

      def serialize(value)
        value ? value.to_i : nil
      end
    end
  end
end

