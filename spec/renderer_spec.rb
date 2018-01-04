require 'mayu/renderer'

RSpec.describe Mayu::Renderer do
  let(:spec) { {} }
  let(:renderer) { described_class.new(spec) }

  describe "#render" do
    let(:source) { {} }
    subject { renderer.render(source) }

    describe do
      let(:spec) { {} }
      let(:source) { double('a', as_json: {}) }

      it { is_expected.to eq({}) }
    end

    describe do
      let(:spec) { {} }
      let(:source) { double('a', as_json: {a: :b}) }

      it { is_expected.to eq({a: :b}) }
    end

    describe do
      let(:spec) { {} }
      let(:source) { double('a', as_json: {a: {b: 1}}) }

      it { is_expected.to eq({a: {b: 1}}) }
    end

    describe do
      let(:spec) { {a: [:c]} }
      let(:source) {
        double('a', as_json: {
          a: double('b',
            as_json: {
              b: 1
            },
            c: 2
          ),
        })
      }

      it { is_expected.to eq(
        {
          a: {b: 1, c: 2}
        }
      )}
    end

    describe do
      let(:spec) { {a: [:c]} }
      let(:source) {
        double('a', as_json: {
          a: [double('b',
            as_json: {
              b: 1
            },
            c: 2
          )],
        })
      }

      it { is_expected.to eq(
        {
          a: [
            {b: 1, c: 2},
          ],
        }
      )}
    end

    describe do
      let(:spec) { {a: {c: :e}} }
      let(:source) {
        double('a', as_json: {
          a: double('b',
            as_json: {
              b: 1
            },
            c: double('c', as_json: {d: 2}, e: 3, f: 4),
          ),
        })
      }

      it { is_expected.to eq(
        {
          a: {b: 1, c: {d: 2, e: 3}},
        }
      )}
    end

    describe do
      let(:spec) { {a: {c: [:e, f: :g]}} }
      let(:source) {
        double('a', as_json: {
          a: double('b',
            as_json: {
              b: 1
            },
            c: double('c', as_json: {d: 2}, e: 3, f: double('e', g: 4)),
          ),
        })
      }

      it { is_expected.to eq(
        {
          a: {b: 1, c: {d: 2, e: 3, f: {g: 4}}},
        }
      )}
    end

    describe do
      let(:spec) { {a: {c: :e}} }
      let(:source) {
        double('a', as_json: {
          a: double('b',
            as_json: {
              b: 1,
            },
            c: nil,
          ),
        })
      }

      it { is_expected.to eq(
        {
          a: {b: 1, c: nil},
        }
      )}
    end

    describe do
      let(:spec) { {a: {c: :e}} }
      let(:source) {
        double('a', as_json: {
          a: double('b',
            as_json: {
              b: 1,
              c: nil,
            },
          ),
        })
      }

      it { is_expected.to eq(
        {
          a: {b: 1, c: nil},
        }
      )}
    end


  end
end
