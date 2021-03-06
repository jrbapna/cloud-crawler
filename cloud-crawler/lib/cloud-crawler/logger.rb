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
require 'logger'

module CloudCrawler
  
  class NullLoger < Logger
    def initialize(*args)
    end

    def add(*args, &block)
    end
  end

  
  # LOGGER = Logger.new($stdout)
  # LOGGER.formatter = Loger::Formatter.new

  LOGGER = NullLoger.new("/dev/null")
  LOGGER.formatter = NullLoger::Formatter.new

  # begin

  # filestring = '/Users/rahulbapna/sites/cloud-crawler/cloud-crawler/logs/master.log'
  # File.delete(filestring)
  # MYLOGGER =  Logger.new(filestring)
  # MYLOGGER.formatter = Logger::Formatter.new
  # MYLOGGER.info "CRAWL BEGIN AT: #{Time.now}"

  #filestring = '/Users/rahulbapna/sites/cloud-crawler/cloud-crawler/logs/errors.log'
  #File.delete(filestring)
  #ERRORS =  Logger.new(filestring)
  #ERRORS.formatter = Logger::Formatter.new

  # catch
  
  # end
 
end
