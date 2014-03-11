l = Linode.new(:api_key => 'L0Z6UD1aCutHHAaLu4KpevPg2PWAmdnIWU9e18ZwlXD3ZKBLbfHPBetJ7pnI96bR')
servers = []
l.linode.list.each { |server|
  if server.status != 1
    next # don't try to connect to powered off servers
  end
  ips = l.linode.ip.list(:LinodeId => server.linodeid)
  ips.each { |ip|
    if ip.ispublic && ip.ipaddress && ! ip.ipaddress.start_with?('192.')
      servers.push(ip.ipaddress)
      break # only need one ip per server
    end
  }
}

set_servers servers

SSHKit::Backend::Netssh.configure do |ssh|
  ssh.ssh_options = {
      user: 'umee',
      password: '3top90!'
  }
end
