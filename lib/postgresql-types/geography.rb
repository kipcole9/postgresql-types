require 'rgeo'

module ActiveRecord
  module Type
    class Geography < Value
      include Mutable
      
      FACTORY = ::RGeo::Geographic.spherical_factory(
        :wkb_parser => {:support_ewkb => true}, :wkb_generator => {:hex_format => true, :type_format => :ewkb, :emit_ewkb_srid => true})
      
      def type
        :geography
      end

      def type_cast_from_user(value)
        return value unless value.present?
        if value.is_a?(Hash)
          lat = value[:lat] || value[:latitude]
          lon = value[:lon] || value[:longitude] || value[:lng]
        elsif value.is_a?(Array)
          lat = value.first
          lon = value.last
        end
        lat && lon ? FACTORY.point(lon.to_f, lat.to_f) : value
      end
      
      def type_cast_from_database(value)
        value ? FACTORY.parse_wkb(value) : nil
      end

      def type_cast_for_database(value)
        value ? value.as_binary : nil
      end
    end
  end
end
