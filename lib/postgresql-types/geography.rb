module ActiveRecord
  module Type
    class Geography < ActiveModel::Type::Value # :nodoc:
      include ActiveModel::Type::Helpers::Mutable
      
      FACTORY = ::RGeo::Geographic.spherical_factory(
        :has_z_coordinate => true,
        :wkb_parser       => {:support_ewkb => true}, 
        :wkb_generator    => {
          :hex_format => true, 
          :type_format => :ewkb, 
          :emit_ewkb_srid => true
        })
      
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
        
      def type
        :geography
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
        value ? FACTORY.parse_wkb(value) : nil
      end

      def serialize(value)
        value ? value.as_binary : nil
      end
    end
  end
end
