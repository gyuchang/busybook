require 'yaml'


class Recorder
  def initialize(app, options={})
    @app = app
    @requests = []
  end

  def call(env)
    status, res_headers, res = @app.call(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']
    body = env['rack.input'].read

    headers = {}
    env.select{|x| x.start_with? 'HTTP_' }.each do |k, v|
      headers[k.sub('HTTP_', '').downcase] = v
    end

    @requests << {
      'method'  => method,
      'headers' => headers,
      'body'    => body,
      'status'  => status
    }

    f = File.open("spec/records/#{ENV['RECORD_NAME']}.yml", 'w')
    f.write(@requests.to_yaml)
    f.close

    [status, res_headers, res]
  end
end

if Rails.env.development?
  Rails.configuration.middleware.insert(0, Recorder)
end
