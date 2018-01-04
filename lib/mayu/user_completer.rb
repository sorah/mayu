require 'graphed_fuzzy_search'

module Mayu
  class UserCompleter
    def initialize(users)
      @cache_key = cache_key_for(users)
      @collection = GraphedFuzzySearch.new(users, attributes: %i(name aliases))
    end

    attr_reader :collection

    def query(str)
      collection.query(str)
    end

    def update(users)
      if @cache_key == cache_key_for(users)
        self
      else
        self.class.new(users)
      end
    end

    private
    
    def cache_key_for(users)
      users.map{ |_| [_.name, _.aliases, _.key] }
    end
  end
end
