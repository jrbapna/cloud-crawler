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
require 'redis'
require 'cloud-crawler/redis_doc_store'
require 'cloud-crawler/logger'
require 'robotex'

module CloudCrawler
  class RedisRobotex < RedisDocStore

    def post_initialize(opts)
      @robotex = Robotex.new(opts[:user_agent])
    end
   
    def allowed?(uri)
      rkey = key_for uri
      if has_key?(rkey)
        @docs[rkey] == "true"
      else
        @docs[rkey] = @robotex.allowed?(uri)
      end
    end

    def make_namespace
      "#{@opts[:job_name]}:robots"
    end

    def key_for(uri)
      uri.host.to_s # for keys like "jrbsilks.com:robots:secure.jrbsilks.com"
    end
    
  end
end
