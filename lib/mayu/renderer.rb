require 'json'

module Mayu

  class Renderer
    def initialize(spec)
      @spec = spec
    end

    def render(obj, spec: @spec)
      r = nil
      case obj
      when nil
        return nil
      when Array
        return obj.map { |_| render(_, spec: spec) }
      when Hash
        r = obj
      else
        case
        when obj.respond_to?(:as_json)
          r = obj.as_json
        when !spec.empty?
          r = {}
        else
          return obj
        end
      end
      next_specs, keys = [spec].flatten.partition { |_| Hash === _ }
      aref = Hash === obj
      r2 = r.transform_values do |v|
        render(v, spec: {})
      end
      keys.each do |k|
        r[k] = render(r.fetch(k) { aref ? obj.fetch(k) { obj.send(k) } : obj.send(k) }, spec: {})
      end
      (next_specs.inject(&:merge) || {}).each do |k, ns|
        r[k] = render(r.fetch(k) { aref ? obj.fetch(k) { obj.send(k) } : obj.send(k) }, spec: ns)
      end
      r2.merge(r)
    end
  end
end
