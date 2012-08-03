require 'logger'

module OPS
  module Config
    attr_writer :log
    attr_writer :logger

    def logging_disabled?
      @log == false
    end

    def logger
      @logger ||= ::Logger.new STDOUT
    end

    def log(sender, log_level, message)
      logger.send(log_level, "[#{sender.class.name}] #{message}") unless logging_disabled?
    end
  end
end
