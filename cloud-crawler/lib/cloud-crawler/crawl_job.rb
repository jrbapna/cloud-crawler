#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
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
require 'cloud-crawler/logger'
require 'cloud-crawler/http'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'pry'

module CloudCrawler
  
    
  class CrawlJob
    include DslCore
  
    def self.init(qless_job)
      @namespace = @opts[:job_name] || 'cc'
      
      @queue_name = @opts[:queue_name]   #ccmc
      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis => qless_job.client.redis)
      @cc_master_q = Redis::Namespace.new("#{@namespace}:ccmq", :redis =>  qless_job.client.redis)
      
      @page_store = RedisPageStore.new(qless_job.client.redis,@opts)
      @robotex_store = RedisRobotex.new(qless_job.client.redis,@opts)


      @bloomfilter = RedisUrlBloomfilter.new(qless_job.client.redis,@opts)
      @queue = qless_job.client.queues[@queue_name]   
      @depth_limit = @opts[:depth_limit]
    end
  
    def self.m_cache
      @m_cache
    end
 
    def self.cache
      @m_cache
    end
    
  
 
       
    def self.get_blocks_from_cache(id)
      @cc_master_q["dsl_blocks:#{id}"] 
    end
    
    
    def self.time_in_milli(time_delay = 0)
      (Time.now + time_delay).strftime('%Y%m%d%H%M%S%L').to_i
    end
    
    def self.perform(qless_job)
      # when testing stuff in this function make sure you remove the error catching in dsl_core (it's parent func)


      super(qless_job)
      init(qless_job)




      #sleep(3)
      # time_delay = 30 # seconds
      # polite_time = @m_cache["time"].to_i || 0
      # if polite_time > time_in_milli
      #   data = qless_job.data.symbolize_keys
      #   @queue.put(CrawlJob, data)
      #   qless_job.cancel
      #   delay(3)        
      # end




      
      LOGGER.info  "CrawlJob: setting up dsl id = #{dsl_id}"
      setup_dsl(dsl_id)  # or could just pass tghe damn blocks in
            

      data = qless_job.data.symbolize_keys



      @cookie_store = CookieStore.new(@opts[:cookies] || {})
      @cookie_store.merge!(data[:cookies], false) unless data[:cookies].blank?


      link, referer, depth = data[:link], data[:referer], data[:depth]
      if referer == "BEGIN"
        # bloomfilter
        qless_job.client.redis.del("#{@opts[:job_name]}:bf")
        
        # crawl count
        qless_job.client.redis.del("#{@opts[:job_name]}:crawl_count")
        
        do_before_crawl_blocks(@page_store)
      end 

      @crawl_count = qless_job.client.redis.incr("#{@opts[:job_name]}:crawl_count")

      if referer == "END" || @crawl_count.to_i >= 50000

        # #MYLOGGER.info "CRAWL COMPLETED AT: #{Time.now}"
        # # / this wont run until you kill the worker
        # str = "redis.call('zrem', 'ql:workers', '"
        # str += qless_job.worker_name
        # str += "')"
        # Process.kill("QUIT",Qless.worker_name.split('.')[1].split('-')[1].to_i)
        # qless_job.client.redis.eval(str)
        
        # this script stops running, else it will error out.
        qless_job.complete 
        return
      end
                  
      http = CloudCrawler::HTTP.new(@opts, @cookie_store)
      #TODO: implement DSL logic to use browser or not

      pages = if keep_redirects? then
          http.fetch_pages(link, referer, depth) 
        else 
          [ http.fetch_page(link, referer, depth) ]
      end
      
      data[:cookies] = @cookie_store.to_s # after http.fetch_page is run, @cookie_store should update

      pages.each do |page|
         url = page.url.to_s

         do_page_blocks(page)
         
         links = links_to_follow(page)       
         links.each do |lnk|
            next if @bloomfilter.visited_url?(lnk)  
            data[:link], data[:referer], data[:depth] =  lnk.to_s, page.url.to_s, page.depth + 1
            next if @depth_limit and data[:depth] > @depth_limit 
            @queue.put(CrawlJob, data)
            @bloomfilter.visit_url(lnk)
            #MYLOGGER.info lnk.to_s
         end
         
         page.discard_doc! if @opts[:discard_page]
         @page_store[url] = page   

     end  

     # we're currently in this job, and even after parsing the pages there are no jobs waiting, so we must be done
     if (@queue.counts["running"] == 1) && @queue.counts["waiting"] == 0
       data[:link], data[:referer], data[:depth] =  :END, :END, 1
       @queue.put(CrawlJob, data)
     end

     # @m_cache["time"] = time_in_milli(time_delay)

    end
   
  end

end
