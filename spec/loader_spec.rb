require 'mayu/loader'

RSpec.describe Mayu::Loader do
  let(:store) do
    double('store', get: {
      maps: {
        map_a: {name: 'map_a'},
        map_b: {name: 'map_b'},
        map_c: {name: 'map_c'},
      },
      aps: {
        ap_a1: {name: 'ap_a1', map_key: 'map_a'},
        ap_b1: {name: 'ap_b1', map_key: 'map_b'},
        ap_b2: {name: 'ap_b2', map_key: 'map_b'},
        ap_b3: {name: 'ap_b3', map_key: 'map_b'},
      },
      users: [
        {key: 'user_a', name: 'user_a'},
        {key: 'user_b', name: 'user_b'},
        {key: 'user_c', name: 'user_c'},
        {key: 'user_d', name: 'user_d'},
      ],
      devices: [
        {key: 'device_a1', user_key: 'user_a', mac: '00:00:5e:00:53:a1'},
        {key: 'device_b1', user_key: 'user_b', mac: '00:00:5e:00:53:b1'},
        {key: 'device_b2', user_key: 'user_b', mac: '00:00:5e:00:53:b2'},
      ],
      associations: [
        {mac: '00:00:5e:00:53:a1', ap_key: 'ap_a1'},
        {mac: '00:00:5e:00:53:b1', ap_key: 'ap_b1'},
        {mac: '00:00:5e:00:53:df', ap_key: 'ap_b2', user_key: 'user_d'},
      ],
    })
  end

  let(:loader) { described_class.new(store: store) }

  describe "relationship:" do
    specify 'map => aps' do
      expect(loader.find_map(:map_a).aps.size).to eq 1
      expect(loader.find_map(:map_a).aps[0].name).to eq 'ap_a1'

      expect(loader.find_map(:map_b).aps.size).to eq 3
      expect(loader.find_map(:map_b).aps[0].name).to eq 'ap_b1'
      expect(loader.find_map(:map_b).aps[1].name).to eq 'ap_b2'
      expect(loader.find_map(:map_b).aps[2].name).to eq 'ap_b3'

      expect(loader.find_map(:map_c).aps.size).to eq 0
    end

    specify 'ap => map' do
      expect(loader.find_ap(:ap_a1).map.name).to eq 'map_a'
      expect(loader.find_ap(:ap_b1).map.name).to eq 'map_b'
      expect(loader.find_ap(:ap_b2).map.name).to eq 'map_b'
      expect(loader.find_ap(:ap_b3).map.name).to eq 'map_b'
    end

    specify 'ap => associations' do
      expect(loader.find_ap(:ap_a1).associations.size).to eq 1
      expect(loader.find_ap(:ap_a1).associations[0].mac).to eq '00:00:5e:00:53:a1'
      expect(loader.find_ap(:ap_b1).associations.size).to eq 1
      expect(loader.find_ap(:ap_b1).associations[0].mac).to eq '00:00:5e:00:53:b1'
      expect(loader.find_ap(:ap_b2).associations.size).to eq 1
      expect(loader.find_ap(:ap_b2).associations[0].mac).to eq '00:00:5e:00:53:df'

      expect(loader.find_ap(:ap_b3).associations.size).to eq 0
    end

    specify 'user => devices' do
      expect(loader.find_user(:user_a).devices.size).to eq 1
      expect(loader.find_user(:user_a).devices[0].mac).to eq '00:00:5e:00:53:a1'

      expect(loader.find_user(:user_b).devices.size).to eq 2
      expect(loader.find_user(:user_b).devices.map(&:mac).sort).to eq \
        %w(00:00:5e:00:53:b1 00:00:5e:00:53:b2)

      expect(loader.find_user(:user_c).devices.size).to eq 0
    end

    specify 'device => user' do
      expect(loader.find_device_by_mac('00:00:5e:00:53:a1').user.name).to eq 'user_a'
      expect(loader.find_device_by_mac('00:00:5e:00:53:b1').user.name).to eq 'user_b'
      expect(loader.find_device_by_mac('00:00:5e:00:53:b2').user.name).to eq 'user_b'
    end

    specify 'device => association' do
      expect(loader.find_device_by_mac('00:00:5e:00:53:a1').association.ap_key).to eq 'ap_a1'
      expect(loader.find_device_by_mac('00:00:5e:00:53:b1').association.ap_key).to eq 'ap_b1'
      expect(loader.find_device_by_mac('00:00:5e:00:53:b2').association).to be_nil
    end

    specify 'association => ap' do
      expect(loader.find_association_by_mac('00:00:5e:00:53:a1').ap.name).to eq 'ap_a1'
      expect(loader.find_association_by_mac('00:00:5e:00:53:b1').ap.name).to eq 'ap_b1'
      expect(loader.find_association_by_mac('00:00:5e:00:53:df').ap.name).to eq 'ap_b2'
    end

    specify 'association => user' do
      expect(loader.find_association_by_mac('00:00:5e:00:53:a1').user.name).to eq 'user_a'
      expect(loader.find_association_by_mac('00:00:5e:00:53:b1').user.name).to eq 'user_b'
      expect(loader.find_association_by_mac('00:00:5e:00:53:df').user.name).to eq 'user_d'
    end

    specify 'association => device' do
      expect(loader.find_association_by_mac('00:00:5e:00:53:a1').device.key).to eq 'device_a1'
      expect(loader.find_association_by_mac('00:00:5e:00:53:b1').device.key).to eq 'device_b1'
      expect(loader.find_association_by_mac('00:00:5e:00:53:df').device).to be_nil
    end


  end
end
