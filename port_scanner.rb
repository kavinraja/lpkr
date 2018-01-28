class Scanner
  require './redis_init'
  no_of_apps = ARGV[0]
  apps = []
  puts "Input #{no_of_apps} number of apps"
  counter = 0
  undeployed_apps_index = 0
  for i in 1..no_of_apps.to_i 
    apps << gets().chomp()
  end

  ips = $redis.smembers("HOST_PORTS_AVAILABLE")
  ips.each do |ip| #deploy apps selecting machines in round robin
    deploy_app(ip)
  end

  if counter < apps.size - 1 # deploy remaining apps after round robin, we can change this to select machine based on least load
    for i in counter..apps.size - 1 
      ip = get_random_free_machine(apps[i])     
      if ip
        deploy_app(ip)
      else
        puts "No free machines"
        undeployed_apps_index = i
        break;
      end
    end
  end

  puts "undeployed apps: #{apps[undeployed_apps_index..-1]}"

  private

  def get_random_free_machine
    available_hosts= $redis.smembers("HOST_PORTS_AVAILABLE")
    available_hosts.size > 0 ? available_hosts.sample : 0
  end

  def deploy_app(ip)
    host = Host.new({:ip=> ip})
    free_port = host.random_free_port
    if free_port
      port = Port.new({:number=> free_port, :host => host})
      app = App.new({:host=> host, :port=> port, :name=> apps[counter++]})
      port.allocate_port
    end 
  end
end