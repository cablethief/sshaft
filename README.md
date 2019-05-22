# SSHaft

A quick [sshd](https://www.openssh.com/) server for reverse tunneling.

Also available on Dockerhub:
https://hub.docker.com/r/cablethief/sshaft

## Overview

Sometimes for whatever reason it is convenient to have a sshd server quickly available to do tunneling to get between networks etc. This docker image provides a way to create a low privilege user and allow port forwarding.

## Features

 - Can set the port sshd listens on.
 - Can setup a low privilege user.
 - Can use root if wanted. 
 - Allows for use of docker port binding by default (Disables IPv6). 
 - Attempts to restrict users to only port forwarding by default.  

## Running

There are two ways to easily run this using standard docker. One is to create a compose file which may be used multiple times and the other is a one liner using normal docker. 

The typical docker line would be:

```
# Run and view output, exit with Ctrl+c, this will create a user "testing" with password "testing" 
# as well as expose ports 22 and 4444
sudo docker run --rm -it -e "USERNAME=testing" -e "PASSWORD=testing" -p 22:22 -p 4444:4444 cablethief/sshaft:latest
# If you do not want to bother with exposing ports you may use your hosts adapter
sudo docker run --rm -it -e "USERNAME=testing" -e "PASSWORD=testing" --network host cablethief/sshaft:latest
```

And using the provided compose file:

```
# This will create and run the container using the variables specified within the file.
sudo docker-compose --file compose.yml up
```

## Environment Variables

Some variables have been provided to allow for customization of the created sshd server. 

Create a lower privileged user, there is no default password so both variables have to be set. 
```
USERNAME=testing 
PASSWORD=testing 
```

Use the root user and set the password, this allows for binding to lower ports. 
```
ROOT_PASSWORD=Testing
```

Set the sshd server port incase you want something other than 22
```
SSH_PORT=12122
```

By default the container will not allow you to get a shell via SSH, you may change this behavior. 

_Without the `ENABLE_SHELL=true` environment variable set SSH clients should use the `-N` flag to not request a shell_

```
ENABLE_SHELL=true
```

Docker does not use IPv6 without starting the daemon with [special flags](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/#how-ipv6-works-on-docker), incase you have those flags you may enable IPv6 in sshd.
```
ENABLE_IPV6=true
```

## IPv6 Nonsense 

Docker [disables ipv6](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/) by default and this makes sshd upset which prevented forwarding without `network_mode host`. By disabling ipv6 in sshd this problem is fixed, a environment flag (`ENABLE_IPV6=true`) is provided to disable this behavior however [further flags](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/#how-ipv6-works-on-docker) need to be set when starting the docker daemon.


## SSH Port Forwarding Basics

In general SSH provides 3 ways to port forward through a tunnel. 

_Without the `ENABLE_SHELL=true` environment variable set SSH clients should use the `-N` flag to not request a shell_

**Dynamic port forwarding** using `-D <port>`, this creates a socks proxy on the ssh client which will tunnel traffic through to the sshd server. This will allow the client access to whatever the server can access over the network.

**Local port forwarding** using `-L [<local ip>]:<local port>:<remote server>:<remote port>`. Will take traffic entered into the `[<local ip>]<local port>` on the ssh client and pass it through the tunnel to a server reachable by the sshd server `<remote server>:<remote port>`.

**Remote port forwarding** using `-R [<remote ip>]:<remote port>:<local server>:<local port>`. Will take traffic sent to the sshd servers `[<remote ip>]:<remote port>` and pass it through the tunnel to a server reachable by the client `<local server>:<local port>`. 

Remote port forwarding is the most likely use for this image. You wish to use a tool like [plink.exe](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) from a dual NATed/whitelisted host to gain access to a second network from a restrictive shell.

For example to reach a remote hosts port 445 which is only accessible from a certain host the following will forward port 445 on the containers (your) sshd server and traffic entered there will reach the remote server 10.1.1.12:445 through the host running plink.exe:

```
# Need echo y to bypass changed hostkey check
C:\ cmd.exe /c echo y | .\plink.exe -N -pw testing root@<your host running this image> -R 445:10.1.1.12:445
```

## Future work

Add [rpivot](https://github.com/klsecservices/rpivot) and environment flags to enable it for reverse dynamic port forwards. 

## Compose file example

```yaml
version: '3'

services:
  sshaft:
    image: cablethief/sshaft
    container_name: sshaft
    # If you are lazy and don't know what ports you want to forward at the moment.
    # network_mode: host
    ports:
      # Always give sub 60 port mappings as strings "https://docs.docker.com/compose/compose-file/"
      - "22:22"
      - "4444:4444"
    environment:
      - USERNAME=testing 
      - PASSWORD=testing 
      # - ROOT_PASSWORD=Testing 
      # - SSH_PORT=22
      # Without the `ENABLE_SHELL=true` environment variable set SSH clients should use the `-N` flag to not request a shell
      # - ENABLE_SHELL=true
      # Ensure you start your docker daemon with the --ipv6 and maybe --fixed-cidr-v6
      # https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/#how-ipv6-works-on-docker
      # - ENABLE_IPV6=true
```
