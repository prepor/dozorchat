# FROM: ActsAsFerret
################################################################################
module CanHasChat
  module Remote
    ################################################################################
    # methods for becoming a daemon on Unix-like operating systems
    module ChatDaemon

      ################################################################################
      def platform_daemon (&block)
        safefork do
          write_pid_file
          trap("TERM") { exit(0) }
          sess_id = Process.setsid
          STDIN.reopen("/dev/null")
          STDOUT.reopen("#{RAILS_ROOT}/log/chat_server.out", "a")
          STDERR.reopen(STDOUT)
          block.call
        end
      end

      ################################################################################
      # stop the daemon, nicely at first, and then forcefully if necessary
      def stop
        pid = read_pid_file
        raise "chat_server doesn't appear to be running" unless pid
        $stdout.puts("stopping chat server...")
        Process.kill("TERM", pid)
        30.times { Process.kill(0, pid); sleep(0.5) }
        $stdout.puts("using kill -9 #{pid}")
        Process.kill(9, pid)
      rescue Errno::ESRCH => e
        $stdout.puts("process #{pid} has stopped")
      ensure
        File.unlink(@config["pid_file"]) if File.exist?(@config["pid_file"])
      end

      ################################################################################
      def safefork (&block)
        @fork_tries ||= 0
        fork(&block)
      rescue Errno::EWOULDBLOCK
        raise if @fork_tries >= 20
        @fork_tries += 1
        sleep 5
        retry
      end

      #################################################################################
      # create the PID file and install an at_exit handler
      def write_pid_file
        open(@config["pid_file"], "w") {|f| f << Process.pid << "\n"}
        at_exit { File.unlink(@config["pid_file"]) if read_pid_file == Process.pid }
      end

      #################################################################################
      def read_pid_file
        File.read(@config["pid_file"]).to_i if File.exist?(@config["pid_file"])
      end

    end
  end
end
