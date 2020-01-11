require 'uri'
require 'net/http'
require 'net/smtp'
require 'mail'
require 'rufus/scheduler'
require 'daemons'

options = {
  log_output: false,
  backtrace:  false,
  multiple:   false
}

POKUPON_URLS = ['https://pokupon.ua', 'https://partner.pokupon.ua'] # ['https://httpstat.us/500', 'https://httpstat.us/400']
SEND_UP_STATUS = true

Mail.defaults do
  delivery_method :smtp, address: 'localhost', port: 1025
end

class MailSender
  def initialize
    @mail = Mail.new do
      from 'site-status@pokupon.ua'
      to   'alert@pokupon.ua'
    end
  end

  def positive(url, status)
    @mail.subject = 'We are back'
    @mail.body = "#{url} is working fine. Status code: #{status}"
    @mail
  end

  def negative(url, status=nil, network_error_msg=nil)
    @mail.subject = 'Oops something went wrong'
    @mail.body = "Oops something went wrong with #{url}. Status code: #{status}"
    
    unless network_error_msg.nil?
      @mail.body = "There are network problems with #{url}, domain and network verification is required"
    end
    
    @mail
  end
end

class StatusChecker
  def initialize(urls)
    @urls = urls
    @db = Array.new(urls.length, '200')
  end

  def check
    @urls.each_with_index do |url, index|
      previous_status = @db[index]
      
      begin # if network or domain error
        current_status = check_response(url)
        if previous_status != current_status
          if current_status == '200'
            MailSender.new.positive(url, current_status).deliver! if SEND_UP_STATUS
          else
            MailSender.new.negative(url, current_status).deliver!
          end
        end
        @db[index] = current_status

      rescue => e
        current_status = 'network_error'
        if previous_status != current_status
          MailSender.new.negative(url, current_status, e.message).deliver!
          @db[index] = current_status
        end
      end

    end
  end

  private

  def check_response(url)
    Net::HTTP.get_response(URI(url)).code
  end
end

Daemons.run_proc('site_checker', options) do
  scheduler = Rufus::Scheduler.new
  checker = StatusChecker.new(POKUPON_URLS)

  scheduler.every '1m' do
    checker.check
  end
  scheduler.join
end
