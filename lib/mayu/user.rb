require 'digest/md5'

require 'mayu/relation'

module Mayu
  User = Struct.new(:key, :name, :aliases, :gravatar_email, keyword_init: true) do
    include Mayu::Relation

    def self.load(obj)
      new(**obj)
    end

    def associations
      devices.map(&:association).compact
    end

    def associated_device_kinds
      associations.map(&:device).compact.map(&:kind).uniq
    end

    def devices_key
      key
    end

    def gravatar_hash
      return nil unless gravatar_email
      @gravatar_hash ||= Digest::MD5.hexdigest gravatar_email.strip.downcase
    end

    relates :devices

    def as_json
      {
        key: key,
        name: name,
        aliases: aliases || [],
        gravatar_hash: gravatar_hash,
      }
    end
  end
end
