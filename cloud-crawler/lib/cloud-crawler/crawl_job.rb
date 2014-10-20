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
    
    
    
    
    def self.perform(qless_job)
      super(qless_job)
      init(qless_job)
      
      LOGGER.info  "CrawlJob: setting up dsl id = #{dsl_id}"
      setup_dsl(dsl_id)  # or could just pass tghe damn blocks in
            

      data = qless_job.data.symbolize_keys
      link, referer, depth = data[:link], data[:referer], data[:depth]  
      if link == "END"
        qless_job.complete
        MYLOGGER.info "CRAWL COMPLETED AT: #{Time.now}"
        # / this wont run until you kill the worker
        str = "redis.call('zrem', 'ql:workers', '"
        str += qless_job.worker_name
        str += "')"
        Process.kill("QUIT",Qless.worker_name.split('.')[1].split('-')[1].to_i)
        qless_job.client.redis.eval(str)
      end
                  
      http = CloudCrawler::HTTP.new(@opts)
      #TODO: implement DSL logic to use browser or not
      pages = if keep_redirects? then
          http.fetch_pages(link, referer, depth) 
        else 
          [ http.fetch_page(link, referer, depth) ]
      end
      
      
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
            MYLOGGER.info lnk.to_s
         end
         
         page.discard_doc! if @opts[:discard_page]
         @page_store[url] = page   

     end  

     if @queue.length == 1
       data[:link], data[:referer], data[:depth] =  :END, :END, 1
       @queue.put(CrawlJob, data)
     end

    end


   
  end

end