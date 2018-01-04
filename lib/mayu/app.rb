require 'sinatra/base'
require 'mayu/renderer'

module Mayu
  def self.app(*args)
    App.rack(*args)
  end

  class App < Sinatra::Base
    CONTEXT_RACK_ENV_NAME = 'mayu.ctx'
    set :root, File.expand_path(File.join(__dir__, '..', '..', 'app'))

    def self.initialize_context(config)
      {
        loader: PeriodicLoader.new(store: config.fetch(:store), interval: config.fetch(:interval, 60).to_i),
      }
    end

    def self.rack(config={})
      klass = App

      context = initialize_context(config)
      lambda { |env|
        env[CONTEXT_RACK_ENV_NAME] = context
        klass.call(env)
      }
    end

    configure do
      enable :logging
    end

    helpers do
      def context
        request.env[CONTEXT_RACK_ENV_NAME]
      end

      def periodic_loader
        context.fetch(:loader)
      end

      def loader
        periodic_loader.loader
      end

      def dummy_ip
        context[:dummy_ip]
      end

      TRUSTED_IPS = /\A127\.0\.0\.1\Z|\A(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\.|\A::1\Z|\Afd[0-9a-f]{2}:.+|\Alocalhost\Z|\Aunix\Z|\Aunix:/i
      def client_ip
        return dummy_ip if dummy_ip
        @client_ip ||= begin
          remote_addrs = request.get_header('REMOTE_ADDR')&.split(/,\s*/)
          filtered_remote_addrs = remote_addrs.grep_v(TRUSTED_IPS)

          if filtered_remote_addrs.empty? && request.get_header('HTTP_X_FORWARDED_FOR')
            forwarded_ips = request.get_header('HTTP_X_FORWARDED_FOR')&.split(/,\s*/)
            filtered_forwarded_ips = forwarded_ips.grep_v(TRUSTED_IPS)

            filtered_forwarded_ips.empty? ? forwarded_ips.first : remote_addrs.first
          else
            filtered_remote_addrs.first || remote_addrs.first
          end
        end
      end
    end

    before do
      periodic_loader.start
    end

    get '/' do
      render :index
    end

    get '/api/search' do
      content_type :json
      if params[:q].nil? || params[:q].to_s.empty?
        halt 400, '{"error": "missing_params"}'
      end

      Renderer.new(
        users: [
          :associated_device_kinds,
        ],
      ).render(
        users: loader.suggest_users(params[:q])
      ).to_json
    end

    get '/api/self' do
      content_type :json
      assoc = loader.find_association_by_ip(client_ip)
      if assoc
        Renderer.new(
          client_ip: client_ip,
          association: [
            :mac,
            :ip,
            user: [devices: [:mac]],
            device: [:mac],
            ap: :map,
          ],
        ).render(
          association: assoc,
        ).to_json
      else
        {
          client_ip: client_ip,
        }.to_json
      end
    end

    get '/api/maps' do 
      content_type :json
      Renderer.new(
        maps: [
          :associations_count,
          :devices_count,
          :users_count,
        ],
      ).render(
        maps: loader.maps.values,
      ).to_json
    end

    get '/api/maps/:key' do
      content_type :json
      map = loader.find_map(params[:key])
      unless map
        halt 404, '{"error": "not_found"}'
      end
      Renderer.new(
        map: [
          :associations_count,
          :devices_count,
          :users_count,
          aps: [
            :associations_count,
            :devices_count,
            :users_count,
          ],
          devices: [
            :association,
            :user,
          ],
        ],
      ).render(
        map: map,
      ).to_json
    end

    get '/api/users/:key' do
      content_type :json
      user = loader.find_user(params[:key])
      unless user
        halt 404, '{"error": "not_found"}'
      end
      Renderer.new(
        user: [
          :associated_device_kinds,
          devices: [
            association: [
              ap: :map,
            ]
          ],
        ],
      ).render(
        user: user,
      ).to_json
    end

    get '/api/aps/:key' do
      content_type :json
      ap = loader.find_ap(params[:key])
      unless ap
        halt 404, '{"error": "not_found"}'
      end
      Renderer.new(
        ap: [
          :associations_count,
          :devices_count,
          :users_count,
          devices: [
            :association,
            :user,
          ],
        ],
      ).render(
        ap: ap,
      ).to_json
    end
  end
end
