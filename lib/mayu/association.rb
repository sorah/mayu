require 'mayu/relation'

module Mayu
  Association = Struct.new(:mac, :ip, :user_key, :ap_key, :updated_at, :appeared_at, :disappeared_at, keyword_init: true) do
    include Mayu::Relation

    def self.load(obj)
      new(**obj)
    end

    def device_key
      mac
    end

    relates :ap
    relates :user
    relates :device

    alias found_user user
    def user
      user_key ? found_user : device.user
    end

    def as_json
      {
        user_key: user&.key,
        ap_key: ap_key,
        updated_at: updated_at,
        appeared_at: appeared_at,
        disappeared_at: disappeared_at,
      }
    end
  end
end
