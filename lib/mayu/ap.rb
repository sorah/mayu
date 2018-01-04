require 'mayu/relation'

module Mayu
  Ap = Struct.new(:key, :name, :description, :map_key, :map_x, :map_y, keyword_init: true) do
    include Mayu::Relation

    def self.load(obj)
      new(**obj)
    end

    relates :map

    relates :associations

    def devices
      @devices ||= associations.map(&:device).compact
    end
    def users
      @users ||= devices.uniq(&:user_key).map(&:user).compact
    end

    def associations_count
      associations.size
    end
    def devices_count
      devices.size
    end
    def users_count
      users.size
    end

    def as_json
      {
        key: key,
        name: name,
        description: description,
        map_key: map_key,
        map_x: map_x,
        map_y: map_y,
      }
    end
  end
end
