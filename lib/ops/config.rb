require "logger"

module OPS
  module Config
    attr_writer :log
    attr_writer :logger
    attr_writer :log_level

    def log?
      !@log.nil? and @log != false
    end

    def logger
      @logger ||= ::Logger.new STDOUT
    end

    def log_level
      @log_level ||= :debug
    end

    def log(sender, message)
      return unless log?
      logger.send(log_level, "[#{sender.class.name}] #{message}")
    end
  end
end
