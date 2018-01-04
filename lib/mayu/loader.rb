require 'mayu/association'
require 'mayu/user'
require 'mayu/device'
require 'mayu/map'
require 'mayu/ap'

require 'mayu/user_completer'

module Mayu
  class Loader
    def initialize(store:, user_completer: nil)
      @store = store
      @cached_user_completer = user_completer
    end

    attr_reader :store

    def load
      objects
      self
    end

    def objects
      @objects ||= store.get
    end

    ###

    def associations
      @associations ||= objects.fetch(:associations).map do |_|
        Association.load(_).tap do |association|
          association._ap_finder = method(:find_ap)
          association._user_finder = method(:find_user)
          association._device_finder = method(:find_device_by_mac)
          association._ensure_relation_finders_satisfied!
        end
      end
    end

    def association_by_mac
      @association_by_mac = associations.map do |_|
        [_.mac, _]
      end.to_h
    end

    def association_by_ip
      @association_by_ip = associations.map do |_|
        [_.ip, _]
      end.to_h
    end

    def associations_by_ap
      @association_by_ap = associations.group_by do |_|
        _.ap_key.to_s
      end.to_h
    end

    def find_association_by_mac(mac)
      association_by_mac[mac]
    end

    def find_association_by_ip(ip)
      association_by_ip[ip]
    end

    def find_associations_by_ap(k)
      associations_by_ap.fetch(k.to_s, [])
    end

    ###

    def users
      @users ||= objects.fetch(:users).map do |_|
        User.load(_).tap do |user|
          user._devices_finder = method(:find_devices_by_user)
          user._ensure_relation_finders_satisfied!
        end
      end
    end

    def user_by_key
      @user_by_key ||= users.map do |_|
        [_.key.to_sym, _]
      end.to_h
    end

    def find_user(k)
      user_by_key[k.to_sym]
    end

    def user_completer
      @user_completer ||= @cached_user_completer ? @cached_user_completer.update(users) : UserCompleter.new(users)
    end

    def suggest_users(query)
      user_completer.query(query)
    end

    ###

    def devices
      @devices ||= objects.fetch(:devices).map do |_|
        Device.load(_).tap do |device|
          device._user_finder = method(:find_user)
          device._association_finder = proc { find_association_by_mac(device.mac) }
          device._ensure_relation_finders_satisfied!
        end
      end
    end

    def device_by_mac
      @device_by_mac ||= devices.reverse_each.map do |device|
        [device.mac, device]
      end.to_h
    end

    def devices_by_user
      @devices_by_user ||= devices.reverse_each.group_by do |device|
        device.user_key
      end
    end

    def find_device_by_mac(k)
      device_by_mac[k]
    end

    def find_devices_by_user(k)
      devices_by_user.fetch(k, [])
    end

    ###

    def maps
      @maps ||= objects.fetch(:maps).map do |k, v|
        [k, Map.load(v).tap do |map|
          map.key = k
          map._aps_finder = proc { find_aps_by_map(k).values }
          map._ensure_relation_finders_satisfied!
        end]
      end.to_h
    end

    def find_map(k)
      maps[k.to_sym]
    end

    ###

    def aps
      @aps ||= objects.fetch(:aps).map do |k,v|
        [k, Ap.load(v).tap do |ap|
          ap.key = k
          ap._map_finder = method(:find_map)
          ap._associations_finder = proc { find_associations_by_ap(k) }
          ap._ensure_relation_finders_satisfied!
        end]
      end.to_h
    end

    def find_ap(k)
      aps[k.to_sym]
    end

    def find_aps_by_map(key)
      aps.select { |k,v| v.map_key.to_s == key.to_s }
    end
  end
end
