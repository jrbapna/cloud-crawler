#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TN)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#





# require 'qless'
# require 'qless/worker'
# require 'qless/threaded_worker'
# require 'qless/threaded_worker/manager'
# require 'qless/threaded_worker/signal_overlord'

# module CloudCrawler
#   class Worker
    
#     def self.run(opts={})      

#       ENV['CONCURRENCY'] = '200' # number of processor threads
      
#       ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
#       ENV['QUEUES'] = opts[:queue_name]
      
#       ENV['JOB_RESERVER'] = opts[:job_reserver]
#       ENV['INTERVAL'] = opts[:interval].to_s
#       ENV['VERBOSE'] = opts[:verbose].to_s
#       ENV['RUN_AS_SINGLE_PROCESS'] = opts[:single_process].to_s

#       # Qless::ThreadedWorker::start
#       manager = Qless::ThreadedWorker::Manager.new
#       manager.async.start

#       overlord = Qless::ThreadedWorker::SignalOverlord.new(manager)
#       overlord.start # blocking call


#     end
    
#   end  
# end







# require 'qless'
# require 'qless/worker'

require 'qless/job_reservers/ordered'
require 'qless/worker'

module CloudCrawler
  class Worker
    
    def self.run(opts={})      
      
      ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
      ENV['QUEUES'] = opts[:queue_name]
      
      ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval].to_s
      ENV['VERBOSE'] = opts[:verbose].to_s
      ENV['RUN_AS_SINGLE_PROCESS'] = opts[:single_process].to_s


      $qless = Qless::Client.new
      queues = opts[:queue_name].split(',').map { |name| $qless.queues[name] }
      job_reserver = Qless::JobReservers::Ordered.new(queues)
      worker = Qless::Workers::ForkingWorker.new(job_reserver, :num_workers => 1, :interval => 1).run


    end
    
  end  
end



