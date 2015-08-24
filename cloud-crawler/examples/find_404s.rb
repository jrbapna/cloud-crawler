#!/usr/bin/env ruby
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
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'
require 'pry'

qurl = URI::encode("http://www.ebay.com/sch/&_nkw=digital+camera")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :job_name, "name of crawl", :short => "-n", :default => "find_404s"
  opt :queue_name, "name of crawl queue", :short => "-q",  :default => "crawls"

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 50
  opt :discard_page, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false


  opt :user_agent, "identify self as CloudCrawler/VERSION", :short => "-A", :default => "CloudCrawler"
  opt :redirect_limit, "number of times HTTP redirects to be followed", :short => "-R", :default => 5
  opt :accept_cookies, "accept cookies from the server and send them back?", :short => "-C",  :default => true
  opt :read_timeout, "HTTP read timeout in seconds",  :short => "-T", :type => :int, :default => nil

  opt :outside_domain, "allow links outside of the root domain", :short => "-U", :default => true
  opt :inside_domain, "allow links inside of the root domain", :short => "-O", :default => true

end


# simple example of SEO tool
# Find all the pages on the website that contain links to the 404s
#  

CloudCrawler::crawl(opts[:urls], opts)  do |cc|


  # DATABASE_URL=$(heroku config:get DATABASE_URL -a ripelink) your_process

  # cc.before_crawl do |page_store|
  #   binding.pry
  # end

  cc.on_every_page do |page|
    # if page.code >= 404 then
    #   s3_cache["404url:#{page.url.to_s}"]=1
    #   s3_cache["404ref:#{page.referer}:#{page.url.to_s}"]=1
    # end
    

    # puts '----------------------------------------------------'
    # puts page.url.to_s
    # Pusher.url = "http://347f85b1a103ce339037:b96d67da0bd891e5439f@api.pusherapp.com/apps/93459"
    # pusher_id = @opts[:original_hosts].first
    # if page.code >= 404
    #   Pusher[pusher_id].trigger('errors', {
    #     message: page.url.to_s
    #   })
    # end
    # Pusher[pusher_id].trigger('current_link', {
    #   message: page.url.to_s
    # })

    page.body.scan(/[\w\d]+[\w\d.-]@[\w\d.-]+\.\w{2,6}/).each do |address|

      # if Address.first(:email => address).nil?
      #   page = Page.first_or_create(
      #     { :url => crawled_page.url.to_s },
      #     {
      #       :site => site,
      #       :created_at => Time.now
      #     }
      #   )

      #   Address.create(
      #     :email => address,
      #     :site => site,
      #     :page => page,
      #     :created_at => Time.now
      #   )

      #   puts address
      # end

      puts '----------------------------------------------------'
      puts page.url.to_s
      Pusher.url = "http://347f85b1a103ce339037:b96d67da0bd891e5439f@api.pusherapp.com/apps/93459"
      pusher_id = 'email_finder'
      if page.code >= 404

      end
      # Pusher[pusher_id].trigger('errors', {
      #   message: page.url.to_s
      # })
      Pusher[pusher_id].trigger('current_link', {
        message: page.url.to_s + ';' + address
      })
      

    end
    



    # # if page.code >= 404
    #   ERRORS.info page.code.to_s + ' ' + page.url.to_s
    # # end
    

  end

end

