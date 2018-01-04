require 'mayu/loader'
require 'thread'

module Mayu
  class PeriodicLoader
    SHUTDOWN_KEY = :mayu_periodic_loader_shutdown
    def initialize(interval:, **options)
      @loaded_at = nil
      @loader = nil
      @interval = interval
      @options = options
      @lock = Mutex.new
      @thread = nil
    end

    attr_reader :loaded_at, :loader

    def start
      return if @thread
      @lock.synchronize do
        return if @thread
        reload
        @thread = Thread.new(&method(:thread))
      end
    end

    def shutdown
      @lock.synchronize do
        if @thread
          @thread[SHUTDOWN_KEY] = true
        end
        @thread = nil
      end
    end

    def reload
      @loaded_at = Time.now
      new_loader = Loader.new(user_completer: @loader&.user_completer, **@options).load
      @loader = new_loader
    end

    def thread
      loop do
        return if @thread[SHUTDOWN_KEY]
        @lock.synchronize do
          reload
        end
        sleep @interval
      rescue Exception => e
        $stderr.puts e.full_message
        sleep @interval
      end
    end
  end
end
