# .
# progress_window.rb
# 
# Copyright 2012 by siberas, http://www.siberas.de
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
module Watobo
  module Gui
    class ProgressWindow < FXTopWindow
      def increment(x)
        @increment += x
      end

      def total=(x)
        @total = x
      end

      def progress=(x)
        @pbar.progress = x
      end

      def title=(new_title)
        @title = new_title
      end

      def task=(new_task)
        @task = new_task
      end

      def job=(new_job)
        @job = new_job
      end

      def update_progress(settings={})
        @update_lock.synchronize do
          @total = settings[:total] unless settings[:total].nil?
          @title = settings[:title] unless settings[:title].nil?
          @task = settings[:task] unless settings[:task].nil?
          @job = settings[:job] unless settings[:job].nil?
          @increment += settings[:increment] unless settings[:increment].nil?
        end
      end

      def initialize(owner, opts={})
        super( owner, 'Progress Bar', nil, nil, DECOR_BORDER, 0, 0, 300, 100, 0, 0, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @update_lock = Mutex.new

        @title_lbl = FXLabel.new(frame, "title")
        @title_lbl.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

        @task_lbl = FXLabel.new(frame, "task")

        @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)

        @job_lbl = FXLabel.new(frame, "job")

        @pbar.progress = 0
        @pbar.total = 100
        @increment = 0
        @total = 100
        @title = "-"
        @job = "-"
        @task = "-"

        add_update_timer(50)
      end

      def add_update_timer(ms)
        @update_timer = FXApp.instance.addTimeout( ms, :repeat => true) {
          @update_lock.synchronize do
            @title_lbl.text = @title
            @task_lbl.text = @task
            @job_lbl.text = @job

            @pbar.increment(@increment)
            @increment = 0
            @pbar.total = @total
          # @pbar.progress = settings[:progress] unless settings[:progress].nil?
          end
        }
      end

    end

  end
end
