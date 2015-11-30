require 'rgeo'

module ActiveRecord
  module Type
    class Geometry < ActiveModel::Type::Value # :nodoc:
      include ActiveModel::Type::Helpers::Mutable
      
      FACTORY = ::RGeo::Geographic.simple_mercator_factory(
        :wkb_parser => {:support_ewkb => true}, :wkb_generator => {:type_format => :ewkb, :hex_format => true, :emit_ewkb_srid => true})
      PROJECTION_FACTORY = FACTORY.projection_factory
      
      def type
        :geometry
      end
      
      def cast(value)
        return value unless value.present?
        if value.is_a?(Hash)
          lat = value[:lat] || value[:latitude]
          lon = value[:lon] || value[:longitude] || value[:lng]
        elsif value.is_a?(Array)
          lat = value.first
          lon = value.last
        end
        lat && lon ? FACTORY.point(lon, lat) : nil
      end

      def deserialize(value)
        value ? FACTORY.unproject(PROJECTION_FACTORY.parse_wkb(geo)) : nil
      end

      def serialize(value)
        value ? FACTORY.project(value).as_binary.unpack('H*').first : nil
      end
    end
  end
end
