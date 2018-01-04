require 'mayu'

stores = []
interval = ENV.fetch('MAYU_WEB_RELOAD_INTERVAL', 60).to_i

%w(ASSOC USER AP).each do |k|
  if ENV["MAYU_#{k}_S3_REGION"] && ENV["MAYU_#{k}_S3_BUCKET"] && ENV["MAYU_#{k}_S3_KEY"]
    regions = ENV["MAYU_#{k}_S3_REGION"].split(?;)
    buckets = ENV["MAYU_#{k}_S3_BUCKET"].split(?;)
    keys = ENV["MAYU_#{k}_S3_KEY"].split(?;)
    regions.zip(buckets, keys).each do |region, bucket, key|
      stores.push(
        Mayu::Stores::S3.new(
          region: region || regions.first,
          bucket: bucket || buckets.first,
          key: key || keys.first,
        )
      )
    end
  end
  if ENV["MAYU_#{k}_FILE"]
    files = ENV["MAYU_#{k}_FILE"].split(?;)
    files.each do |file|
      stores.push(
        Mayu::Stores::File.new(
          path: file,
        )
      )
    end
  end
end

store = Mayu::Stores::Concat.new(stores: stores)
loader = Mayu::Loader.new(store: store).load
#binding.irb

run Mayu.app(
  store: store,
  refresh_interval: interval,
)
