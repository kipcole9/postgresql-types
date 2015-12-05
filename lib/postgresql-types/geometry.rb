require 'rgeo'

module ActiveRecord
  module Type
    class Geometry < ActiveModel::Type::Value # :nodoc:
      include ActiveModel::Type::Helpers::Mutable
      
      FACTORY = ::RGeo::Geographic.simple_mercator_factory(
        :has_z_coordinate => true,
        :wkb_parser => {:support_ewkb => true}, 
        :wkb_generator => {
          :type_format => :ewkb, 
          :hex_format => true, 
          :emit_ewkb_srid => true
      })
      
      PROJECTION_FACTORY = FACTORY.projection_factory
      
      def type
        :geometry
      end
      
        # json-schema format
      def self.as_json(options = {})
        {
          properties: {
            latitude: {
              type: :number, 
              description: I18n.t("schema.property.latitude")
            },
            longitude: {
              type: :number, 
              description: I18n.t("schema.property.longitude")
            },
            altitude: {
              type: :number,
              default: 0,
              description: I18n.t("schema.property.altitude")
            }
          },
          required: [
            :latitude, :longitude
          ]
        }
      end
      
      def cast(value)
        return value unless value.present?
        if value.is_a?(Hash)
          lat = value[:lat] || value[:latitude]
          lon = value[:lon] || value[:longitude] || value[:lng]
          alt = value[:alt] || value[:altitude]  || 0
        elsif value.is_a?(Array)
          lat = value.first
          lon = value.second
          alt = value.third || 0
        end
        lat && lon ? FACTORY.point(lon.to_f, lat.to_f, alt.to_f) : value
      end

      def deserialize(value)
        value ? FACTORY.unproject(PROJECTION_FACTORY.parse_wkb(value)) : nil
      end

      def serialize(value)
        value && value.is_a?(RGeo::Geographic::ProjectedPointImpl) ? FACTORY.project(value).as_binary.unpack('H*').first : nil
      end
    end
  end
end
