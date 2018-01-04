require 'mayu/stores/base'
require 'json'

module Mayu
  module Stores
    class File < Base
      def initialize(path:)
        @path = path
      end

      attr_reader :path

      def put(obj)
        ::File.write path, "#{for_json(obj).to_json}\n"
      end

      def get
        from_json JSON.parse(::File.read(path), symbolize_names: true)
      rescue Errno::ENOENT
        return nil
      end
    end
  end
end

