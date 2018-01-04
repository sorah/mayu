require 'wlc_snmp'
require 'mayu/stores/memory'
require 'mayu/cisco_wlc_collector'

RSpec.describe Mayu::CiscoWlcCollector do
  let(:store) { Mayu::Stores::Memory.new }

  let(:ap_mac_for_key) { false }
  let(:use_wlc_user) { false }
  let(:ttl) { 60 }
  let(:last_associations) { nil }

  def mock_client(key, ap_key: key, user: 'NA', uptime: 10, ap: nil)
    double(
      "c-#{key}",
      ip_address: '192.0.2.1',
      mac_address: "00:00:5e:00:53:0#{key}",
      user: user,
      uptime: uptime,
      ap: ap || double("c-#{ap_key}-A", name: "c-#{ap_key}-A", mac_address: '00:00:5e:00:53:a0'),
    )
  end

  def perform!
    described_class.new(
      host: 'dummy',
      community: 'public',
      store: store,
      ap_mac_for_key: ap_mac_for_key,
      use_wlc_user: use_wlc_user,
      ttl: ttl,
      last_associations: last_associations,
    ).perform!
  end

  let(:clients) { [] }
  let(:dummy_wlc_snmp) do
    double('dummy_wlc_snmp', clients: clients)
  end

  let(:time) { Time.now }

  before do
    allow(Time).to receive(:now).and_return(time)
    allow(WlcSnmp::Client).to receive(:new).with(host: 'dummy', community: 'public').and_return(dummy_wlc_snmp)
  end

  describe "#perform!" do
    subject { store.get.fetch(:associations) }

    describe "list management:" do
      context "when 1 association appears" do
        let(:clients) { [mock_client('a')] }

        before do
          perform!
        end

        it "adds associations" do
          expect(subject.size).to eq 1
          expect(subject[0][:mac]).to eq clients[0].mac_address
          expect(subject[0][:ap_key]).to eq clients[0].ap.name
          expect(subject[0][:user_key]).to be_nil
          expect(subject[0][:appeared_at]).to eq(time - 10)
          expect(subject[0][:updated_at]).to eq(time)
        end
      end

      context "when new association appear" do
        let(:clients) { [mock_client('a')] }

        before do
          perform!
          clients.push mock_client('b')
          allow(Time).to receive(:now).and_return(time + 1)
          perform!
        end

        it "adds associations" do
          expect(subject.size).to eq 2
          expect(subject[1][:mac]).to eq clients[1].mac_address
          expect(subject[1][:ap_key]).to eq clients[1].ap.name
          expect(subject[1][:user_key]).to be_nil
          expect(subject[1][:appeared_at]).to eq(time - 9)
          expect(subject[1][:updated_at]).to eq(time + 1)
        end

        it "doesn't change existing appeared_at and updated_at" do
          expect(subject[0][:appeared_at]).to eq(time - 10)
          expect(subject[0][:updated_at]).to eq(time)
        end
      end

      context "when association remains" do
        let(:clients) { [mock_client('a')] }

        before do
          perform!
          allow(Time).to receive(:now).and_return(time + 1)
          perform!
        end

        it "doesn't change existing appeared_at and updated_at" do
          expect(subject[0][:appeared_at]).to eq(time - 10)
          expect(subject[0][:updated_at]).to eq(time)
        end
      end

      context "when association remains, but its attribute has changed" do
        let(:clients) { [mock_client('a')] }

        before do
          perform!
          clients[0] = mock_client('a', ap_key: 'b')
          allow(Time).to receive(:now).and_return(time + 1)
          perform!
        end

        it "updates attributes" do
          expect(subject.size).to eq 1
          expect(subject[0][:mac]).to eq clients[0].mac_address
          expect(subject[0][:ap_key]).to eq clients[0].ap.name
          expect(subject[0][:user_key]).to be_nil
          expect(subject[0][:appeared_at]).to eq(time - 9)
        end

        it "updates updated_at" do
          expect(subject[0][:updated_at]).to eq(time + 1)
        end
      end


      context "when some of last associations disappear" do
        let(:clients) { [mock_client('a'), mock_client('b')] }

        before do
          perform!
          clients.pop
          allow(Time).to receive(:now).and_return(time + 1)
          perform!
        end

        it "records disappeared_at" do
          expect(subject.size).to eq 2
          expect(subject[1][:disappeared_at]).to eq time+1
        end
      end

      context "when disappeared associations spent their TTL" do
        let(:clients) { [mock_client('a'), mock_client('b')] }

        before do
          perform!

          clients.pop
          allow(Time).to receive(:now).and_return(time + 1)
          perform!

          allow(Time).to receive(:now).and_return(time + 90)
          perform!
        end

        it "removes disappeared and expired associations" do
          expect(subject.size).to eq 1
          expect(subject[0][:mac]).to eq clients[0].mac_address
        end
      end
    end

    context "with :ap_mac_for_key" do
      let(:ap_mac_for_key) { true }
      let(:clients) { [mock_client('a')] }

      before do
        perform!
      end

      it "uses MAC address for ap_key" do
        expect(subject[0][:ap_key]).to eq clients[0].ap.mac_address
      end
    end

    context "with :use_wlc_user" do
      let(:use_wlc_user) { true }

      context "when username is present" do
        let(:clients) { [mock_client('a', user: 'sakuma')] }

        before do
          perform!
        end

        it "sets username present in WLC" do
          expect(subject[0][:user_key]).to eq clients[0].user
        end
      end

      context "when username is not present (NA)" do
        let(:clients) { [mock_client('a')] }

        before do
          perform!
        end

        it "sets user_key to nil" do
          expect(subject[0][:user_key]).to be_nil
        end
      end
    end
  end
end
