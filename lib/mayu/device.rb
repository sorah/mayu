require 'mayu/relation'

module Mayu
  Device = Struct.new(:key, :user_key, :mac, :kind, :note, keyword_init: true) do
    include Mayu::Relation

    def self.load(obj)
      new(**obj)
    end

    relates :user

    relates :association

    def as_json
      {
        key: key,
        user_key: user_key,
        kind: kind,
      }
    end
  end
end
