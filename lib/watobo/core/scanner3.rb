# .
# scanner3.rb
# 
# Copyright 2013 by siberas, http://www.siberas.de
# 
# This file is part of WATOBO (Web Application Tool Box)
#        http://watobo.sourceforge.com
# 
# WATOBO is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 2 of the License.
# 
# WATOBO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with WATOBO; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# .
# @private 
module Watobo#:nodoc: all
  class Scanner3
    
    include Watobo::Constants
    include Watobo::Subscriber

    SCANNER_READY = 0x0000
    SCANNER_RUNNING = 0x0001

    GENERATION_STARTED = 0x0100
    GENERATION_FINISHED = 0x0200
    class Worker
      include Watobo::Constants
      include Watobo::Subscriber
      
      attr :engine
      
      STATE_IDLE = 0x00
      STATE_RUNNING = 0x01
      STATE_WAIT_FOR_LOGIN = 0x02
      
      def state
        state = nil
        @state_mutex.synchronize do 
          state = @state
        end
        state
      end
      
      def run
        @state_mutex.synchronize do @state = STATE_RUNNING; end
        Thread.new{ @engine.run }
      end
      
      def start
        @engine = Thread.new(@tasks, @logged_out_queue, @prefs){ |tasks, logged_out_queue, prefs|
          relogin_count = 0
          loop do
            task = tasks.deq
            begin
              #puts "RUNNING #{task[:module]}"
              request, response = task[:check].call()
              
              
              unless prefs[:logout_signatures].empty? or prefs[:auto_login] == false
                logged_out = false
                prefs[:logout_signatures].each do |sig|
                  logged_out = true if response.join =~ /#{sig}/
                end
                
                if logged_out 
                  @state_mutex.synchronize do @state = STATE_WAIT_FOR_LOGIN; end
                  logged_out_queue.push self
                  # stop current thread, will be waked-up by scanner
                  Thread.stop
                  relogin_count += 1
                  @state_mutex.synchronize do @state = STATE_RUNNING; end
                  unless relogin_count > 5
                     request, response = task[:check].call()
                  end 
                end
              end
              
              unless prefs[:scanlog_name].nil?
                chat = Chat.new(request, response, :id => 0, :chat_source => prefs[:chat_source])
                Watobo::DataStore.add_scan_log(chat, prefs[:scanlog_name])
              end
            rescue => bang
              puts "!!! #{task[:module]} !!!"
              puts bang
              puts bang.backtrace if $DEBUG
            ensure
              #puts "FINISHED #{task[:module]}"
              notify(:task_finished, task[:module])
            end
            Thread.exit if relogin_count > 5
            relogin_count = 0
          end
        }
      end

      def stop
        @state = STATE_IDLE
        Thread.kill @engine if @engine.alive?
      end
      
      def wait_for_login?
        state = false
        @state_mutex.synchronize do
          state = ( @state == STATE_WAIT_FOR_LOGIN )
        end
        state
      end
      
      def running?
        @state_mutex.synchronize do
          running = ( @state == STATE_RUNNING )
        end
        running
      end

      def initialize(task_queue, logged_out_queue, prefs)
        @engine = nil
        @tasks = task_queue
        @logged_out_queue = logged_out_queue
        @prefs = prefs
        @relogin_count = 0
        @state_mutex = Mutex.new
        @state = STATE_IDLE
      
      end

    end
    #
    #  E N D   O F   W O R K E R

    def tasks
      @tasks
    end
    
    def status_running?
      ( status & SCANNER_RUNNING ) > 0
    end
    
    def generation_finished?
      ( status & GENERATION_FINISHED ) > 0
    end
    
    def finished?
      return true if (
         status_running? &&
          ( @tasks.num_waiting == @workers.length ) &&
          ( @tasks.size == 0 ) &&
          generation_finished?
         )
      false
    end

    def running?()     
        return false if (
         status_running? &&
          ( @tasks.num_waiting == @workers.length ) &&
          ( @tasks.size == 0 ) &&
          generation_finished?
         )        
        return true if status_running?
      return false
    end

    def stop()
      begin
        @workers.each do |w|
          w.stop
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    def cancel()
      begin
        @workers.each do |w|
          w.stop
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    def continue()
      # TODO
    end

    def progress
      @task_count_lock.synchronize do
        YAML.load(YAML.dump(@task_counter))
      end
    end
    
    def sum_total
      sum = 0
      @task_count_lock.synchronize do
        sum = @task_counter.values.inject(0){|i,v| i + v[:total] }
      end
      sum
    end
    
    def sum_progress
      sum = 0
      @task_count_lock.synchronize do
        sum = @task_counter.values.inject(0){|i,v| i + v[:progress] }
      end
      sum
    end

    def run( check_prefs={} )
      # @sites_online.clear
      @uniqueRequests = Hash.new
      set_status_running

      @login_count = 0
      @max_login_count = 20

      Thread.new{
        size = -1
        loop do
          if @tasks.num_waiting == @workers.length and @tasks.size == 0 and generation_finished?
            @workers.map{|w| w.stop }
            # suizide!
            Thread.exit
          end
          
          if @logged_out.size == ( @workers.length - @tasks.num_waiting) or @tasks.num_waiting == @workers.size
            @logged_out.clear
            #puts "!LOGOUT DETECTED!\n#{@logged_out.size} - #{@workers.length} - #{@tasks.num_waiting}\n\n"
            begin         
              puts "Run login ..."
              login
              @workers.each do |wrkr|
               # puts "State: #{wrkr.state}"
                if wrkr.wait_for_login?
                  wrkr.engine.run
                end
              end
                           
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          
          end
          
          sleep 1
        end
      }

      @prefs.update check_prefs
      msg = "\n[Scanner] Starting Scan ..."
      notify(:logger, LOG_INFO, msg )
      puts msg
      
      # starting workers before check generation
      start_workers( @prefs)
      @max_tasks = 1000
      
      # start check generation in seperate thread
      Thread.new{
        begin
        set_status GENERATION_STARTED
        @chat_list.uniq.each do |chat|
        # puts chat.request.url.to_s
          @active_checks.uniq.each do |ac|
            ac.reset()
            if site_alive?(chat) then
              ac.generateChecks(chat){ |check|
                while @tasks.size > @max_tasks
                  sleep 1
                end
                task = { :module => ac,
                  :check => check
                }
                @tasks.push task
              }
            end
          end
        end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        ensure
          set_status GENERATION_FINISHED
        end
      }

    end

    def initialize(chat_list=[], active_checks=[], passive_checks=[], prefs={})
      @chat_list = chat_list
      @active_checks = []
      @passive_checks = passive_checks
      
      @tasks = Queue.new
      @logged_out = Queue.new
      
      @workers = []

     

      @status_lock = Mutex.new

      @task_count_lock = Mutex.new
      @task_counter = {}

      # @onlineCheck = OnlineCheck.new(@project)
      msg = "Initializing Scanner ..."
      notify(:logger, LOG_INFO, msg)
      puts msg
      
      @prefs = Watobo::Conf::Scanner.to_h

      @prefs.update prefs
      #puts "set up scanner"
      #puts @prefs[:login_chats]
      #puts @prefs[:logout_signatures]
      puts "= create scanner =" if $DEBUG
      puts @prefs.to_yaml 

      unique_checks = {}
      active_checks.each do  |x|
        if x.respond_to? :new
          ac = x.new(self.object_id, @prefs)
        else
          ac = x
        end
        unique_checks[ac.class.to_s] = ac unless unique_checks.has_key?(ac.class.to_s)
      end
      unique_checks.each_value do |check|
        @active_checks << check
      end

      puts "#ActiveModules: #{@active_checks.length}"

      @active_checks.uniq.each do |check|

        check.resetCounters()
        @chat_list.each_with_index do |chat, index|
          #print "."
          check.updateCounters(chat, @prefs)
          puts "* [#{index}] CheckCounter #{chat.id}: #{check.check_name} - #{check.numChecks}"
        end

        # @numTotalChecks += check.numChecks
        # cn = check.info[:check_name]
        # puts "+ add check: #{cn}"
        # notify(:logger, LOG_INFO, "add check #{cn}")
        @task_counter[check.check_name] = { :total => check.numChecks,
          :progress => 0
        }
      end
       @status = SCANNER_READY
      msg = "Scanner Ready!"
      notify(:logger, LOG_INFO, msg)
      puts msg
    end

    private

    def set_status_running
      s = ( status | SCANNER_RUNNING )
      set_status( s )
    end

    def set_status(s)
      @status_lock.synchronize {
        @status |= s
      }
    end

    def status
      @status_lock.synchronize {
        return @status
      }
    end

    def start_workers(check_prefs)
      num_workers = @prefs.has_key?(:max_parallel_checks) ? @prefs[:max_parallel_checks] : Watobo::Conf::Scanner.max_parallel_checks
      
      puts "Starting #{num_workers} Workers ..."

      num_workers.times do |i|
        print "... #{i + 1}"
        w = Scanner3::Worker.new(@tasks, @logged_out, check_prefs)

        w.subscribe(:task_finished){ |m|
          @task_count_lock.synchronize do
            cn = m.check_name
            @task_counter[cn][:progress] += 1
          end
        }
        
        @logout_count ||= 0
        @logout_count_lock ||= Mutex.new
        @num_waiting = 0
          
        w.start
        @workers << w
      end
      print "\n"

    end
    
    def login
       puts "do relogin"
       login_chats = Watobo::Conf::Scanner.login_chat_ids.uniq.map{|id| Watobo::Chats.get_by_id(id) }  
           #  puts "running #{login_chats.length} login requests"
           #  puts login_chats.first.class            
             
      @active_checks.first.runLogin(login_chats, @prefs)
      
    end

    def site_alive?(chat)
      @sites_alive ||= Hash.new
      site = chat.request.site
      return true if @sites_alive.has_key? site

      if Watobo::HTTPSocket.siteAlive?(chat)
      @sites_alive[site] = true
      return true
      end
      return false
    end

  end
end
