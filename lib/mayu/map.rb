module Mayu
  Map = Struct.new(:key, :name, :url, :fg_color, :bg_color, :highlight_color, keyword_init: true) do
    include Mayu::Relation

    def self.load(obj)
      new(**obj)
    end

    relates :aps

    def associations
      @associations ||= aps.flat_map(&:associations)
    end
    def devices
      @devices ||= aps.flat_map(&:devices)
    end
    def users
      @users ||= aps.flat_map(&:users)
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
        url: url,
        fg_color: fg_color,
        bg_color: bg_color,
        highlight_color: highlight_color,
      }
    end
  end
end
