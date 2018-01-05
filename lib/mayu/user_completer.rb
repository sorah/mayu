require 'graphed_fuzzy_search'

module Mayu
  class UserCompleter
    ShallowUser = Struct.new(:key, :name, :aliases)

    def initialize(users)
      shallow = shallow_users(users)
      @cache_key = shallow
      @collection = GraphedFuzzySearch.new(shallow, attributes: %i(name aliases))
    end

    attr_reader :collection

    def query(str)
      collection.query(str).map(&:key)
    end

    def update(users)
      if @cache_key == shallow_users(users)
        self
      else
        self.class.new(users)
      end
    end

    private
    
    def shallow_users(users)
      users.map{ |_| ShallowUser.new(_.key, _.name, _.aliases) }
    end
  end
end
