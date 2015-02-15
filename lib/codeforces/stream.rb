require "celluloid"
require "logger"
require "codeforces"
require "codeforces/stream/version"

module Codeforces

  module Stream

    class Status

      include ::Celluloid

      attr_reader :last_id
      attr_reader :last_status
      attr_reader :logger

      def initialize
        @last_id      = 0
        @last_status  = {}
        @logger       = ::Logger.new(STDOUT)
        logger.level  = ::Logger::Severity::INFO
      end

      def pending?(status)
        if last_id < status.id && last_status[status.id].nil?
          true
        elsif not last_status[status.id].nil?
          true
        else
          false
        end
      end

      def wait
        loop { wait_func }
      end

      def wait_func
        status = receive {|s| pending?(s) }
        if last_status[status.id].nil?
          last_status[status.id] = status
          @last_id = status.id
        end
        unless status.verdict == "TESTING"
          logger.debug status
          puts "##{status.id}: #{status.author.members.first.handle}: #{status.verdict}"
          last_status.delete status.id
        end
      end


      # @example
      # Status.start do |receiver|
      #   Codeforces.api.problemset.recent_status.reverse_each do |s|
      #     receiver.mailbox << s
      #   end
      # end
      def self.start(&callback)
        receiver = new
        receiver.async.wait
        loop do
          callback.call(receiver)
          sleep 5
        end
      end

    end

  end

end

