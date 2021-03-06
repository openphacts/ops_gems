########################################################################################
#
# The MIT License (MIT)
# Copyright (c) 2012 BioSolveIT GmbH
#
# This file is part of the OPS gem, made available under the MIT license.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For further information please contact:
# BioSolveIT GmbH, An der Ziegelei 79, 53757 Sankt Augustin, Germany
# Phone: +49 2241 25 25 0 - Email: license@biosolveit.de
#
########################################################################################

require 'logger'

module OPS

  class Error < StandardError; end
  class MissingArgument < Error; end
  class InvalidArgument < Error; end
  class InvalidJsonResponse < Error; end
  class ServerResponseError < Error; end
  class NotFoundError < ServerResponseError; end
  class ForbiddenError < ServerResponseError; end
  class UriTooLarge < ServerResponseError; end
  class BadRequestError < ServerResponseError; end
  class GatewayTimeoutError < ServerResponseError; end
  class InternalServerError < ServerResponseError; end

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
