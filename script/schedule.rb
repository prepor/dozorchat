require 'rubygems'
require 'daemons'
APP_DIR = File.join(File.dirname(File.expand_path(__FILE__)), '..')

Daemons.run_proc(
  'schedule',
  :dir_mode => :normal, 
  :dir => File.join(APP_DIR, 'log'),
  :multiple => false,
  :backtrace => true,
  :monitor => true,
  :log_output => true
) do


  Dir.chdir(APP_DIR)


  require File.join('config', 'environment')

  begin

    require 'rufus/scheduler'
    scheduler = Rufus::Scheduler.new
    scheduler.start
    

    scheduler.schedule_every('60s') do

       ChatUser.find(:all, :conditions => ["last_activity < ?", (Time.now - 15.minutes).to_s(:db)]).each do |user|

          crew=user.crew
          user.destroy
          crew.destroy if crew.chat_users.length < 1
        end
        
    end
    scheduler.join
  rescue => e
    RAILS_DEFAULT_LOGGER.warn "Exception in schedule: #{e.inspect}"
    exit
  end
end