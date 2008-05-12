#
# TODO
# In retrospect ( after going over some other code that used it ) this code
# is a useless reproduction of Mutex.  This should be replaced with usage
# of Mutex immediately.
# 
module CanHasChat
  module Remote
    module Lockable

      class ThreadAlreadyLocked < RuntimeError; end
      class ThreadNotLocked < RuntimeError; end

      def sleep_until_unlocked
        while self.locked?
          @owning_thread.join if self.locked?
        end
        return nil
      end

      def lock!
        raise ThreadAlreadyLocked if @locked
        @locked = true
        @owning_thread = Thread.current
        return nil
      end
  
      def unlock!
        raise ThreadNotLocked unless @locked
        @locked = false
        @owning_thread = nil
        return nil
      end
  
      def locked?
        return @locked
      end
  
      def synchronize_with(&block)
        begin
          self.sleep_until_unlocked
          self.lock!
          yield(self)
        rescue
          msg = "Thread error, #{self}: #{$!.to_s}"
          if @logger
            @logger.error msg
          else
            puts msg
          end
          raise
        ensure
          self.unlock!
        end
      end
    end
  end
end