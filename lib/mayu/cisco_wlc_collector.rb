require 'wlc_snmp'
require 'mayu/association'

module Mayu
  class CiscoWlcCollector
    def initialize(host:, community: 'public', store:, ap_mac_for_key: false, use_wlc_user: false, ttl: 300, last_associations: nil)
      @host = host
      @community = community
      @store = store
      @ap_mac_for_key = ap_mac_for_key
      @use_wlc_user = use_wlc_user
      @last_associations = last_associations
      @ttl = ttl
    end

    attr_reader :host, :community, :store
    attr_reader :ttl

    def ap_mac_for_key?
      @ap_mac_for_key
    end

    def use_wlc_user?
      @use_wlc_user
    end

    def perform!
      store.put(associations: associations.map(&:to_h))
    end

    def time
      @time ||= Time.now
    end

    def associations
      @associations = []

      new_mac_addresses = current_associations_by_mac.keys - last_associations_by_mac.keys
      left_mac_addresses = last_associations_by_mac.keys - current_associations_by_mac.keys
      kept_mac_addresses = last_associations_by_mac.keys & current_associations_by_mac.keys

      left_mac_addresses.each do |mac|
        assoc = last_associations_by_mac.fetch(mac)
        unless assoc.disappeared_at
          assoc = assoc.dup
          assoc.disappeared_at = time
          assoc.updated_at = time
        end
        @associations << assoc
      end
      new_mac_addresses.each do |mac|
        @associations << current_associations_by_mac.fetch(mac)
      end

      kept_mac_addresses.each do |mac|
        last = last_associations_by_mac.fetch(mac)
        current = current_associations_by_mac.fetch(mac)
        if last.ap_key != current.ap_key || last.ip != current.ip
          @associations << current
        else
          @associations << last
        end
      end

      @associations.reject! do |assoc|
        assoc.disappeared_at && (time - assoc.disappeared_at) >= ttl
      end

      @associations.sort_by! do |assoc|
        assoc.mac
      end

      @associations
    end

    def last_associations_by_mac
      @last_associations ||= begin
        assocs = store.get&.yield_self { |data|
          data.fetch(:associations).map { |_| Association.load(_) }
        } || []
        assocs.map{ |_| [_.mac, _] }.to_h
      end
    end

    def current_associations_by_mac
      @current_associations ||= wlc.clients.map do |client|
        Association.new(
          mac: client.mac_address,
          ip: client.ip_address,
          ap_key: ap_mac_for_key? ? client.ap.mac_address : client.ap.name,
          user_key: use_wlc_user? ? (client.user != 'NA' ? client.user : nil) : nil,
          appeared_at: time - client.uptime,
          updated_at: time,
        )
      end.map{ |_| [_.mac, _] }.to_h
    end

    def wlc
      @wlc ||= WlcSnmp::Client.new(host: host, community: community)
    end
  end
end
