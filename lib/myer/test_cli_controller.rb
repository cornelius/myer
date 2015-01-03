class TestCliController
  attr_accessor :out

  def initialize
    @out = STDOUT
  end

  def local(executable)
    Dir.mktmpdir do |dir|
      pin = "xyz"

      cmd = "#{executable} -pin=#{pin} -logfile=/dev/null #{dir}/data"
      io = IO.popen(cmd)

      sleep(1)

      begin
        full("localhost", pin)
      ensure
        Process.kill("INT", io.pid)
      end
    end
  end

  def full(server, pid)
    admin_api = MySelf::Api.new
    admin_api.server = server

    admin_api.user, admin_api.password = admin_api.admin_register(pid)

    token = admin_api.create_token

    user_api = MySelf::Api.new
    user_api.server = server

    user_api.user, user_api.password = admin_api.register(token)

    bucket = user_api.create_bucket

    content = "octopus"

    item = user_api.create_item(bucket, content)

    items = user_api.get_items(bucket)

    if items.size == 1 && items[0].id == item && items[0].content == content
      @out.puts "Full acceptance test passed"
    else
      @out.puts "Fill acceptance test failed"
    end
  end
end
