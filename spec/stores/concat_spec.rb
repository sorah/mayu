require 'mayu/stores/concat'

RSpec.describe Mayu::Stores::Concat do
  let(:store_a) do
    {
      only_a: 1,
      array: [:a1, :a2],
      hash: {foo: 1, bar: 2},
      other: 1,
    }
  end
  let(:store_b) do
    {
      only_b: 2,
      array: [:b1, :b2],
      hash: {bar: 3, baz: 4},
      other: 2,
    }
  end

  let(:stores) do
    [
      double('store-a', get: store_a),
      double('store-b', get: store_b),
    ]
  end
  let(:result) { described_class.new(stores: stores).get }

  describe "#get" do
    describe "key exists only in either" do
      subject { [result.fetch(:only_a), result.fetch(:only_b)] }
      it { is_expected.to eq [1, 2] }
    end
    describe "array" do
      subject { result.fetch(:array) }
      it { is_expected.to eq [:a1, :a2, :b1, :b2] }
    end
    describe "hash" do
      subject { result.fetch(:hash) }
      it { is_expected.to eq(foo: 1, bar: 3, baz: 4) }
    end
    describe "other" do
      subject { result.fetch(:other) }
      it { is_expected.to eq(2) }
    end
  end
end
