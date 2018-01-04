require 'mayu/stores/s3'
require 'aws-sdk-s3'
require 'json'

module Mayu
  module Stores
    class S3 < Base
      def initialize(region:, bucket:, key:)
        @region = region
        @bucket = bucket
        @key = key
      end

      def put(obj)
        s3.put_object(
          bucket: @bucket,
          key: @key,
          content_type: 'application/json',
          body: "#{for_json(obj).to_json}\n",
        )
      end

      def get
        json = s3.get_object(
          bucket: @bucket,
          key: @key,
        ).body.read
        from_json JSON.parse(json, symbolize_names: true)
      rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied
        return nil
      end

      def s3
        @s3 ||= Aws::S3::Client.new(
          region: @region,
        )
      end
    end
  end
end
