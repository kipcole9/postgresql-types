require 'rgeo'

module RGeo
  module Json
    def as_json(*args)
      {
        point: {
          latitude:   self.latitude,
          longitude:  self.longitude,
          altitude:   self.z
        }
      }
    end
  end
end


class RGeo::Geographic::ProjectedPointImpl
  include ::RGeo::Json
end

class RGeo::Geographic::SphericalPointImpl
  include ::RGeo::Json
end
