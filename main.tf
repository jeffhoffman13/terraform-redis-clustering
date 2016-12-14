# Configure the Docker provider
provider "docker" {
	host = "unix:///var/run/docker.sock"
}

resource "docker_container" "redis-servers" {
	image = "${docker_image.redis.latest}"
	name = "redis-${format("%02d", count.index+1)}"

	count = 8

	restart = "always"

	volumes {
		container_path  = "/usr/local/etc/redis"
		host_path = "/home/dmportella/_workspaces/terraform/redis-cluster/config/redis"
		read_only = false
	}

	command = ["redis-server", "/usr/local/etc/redis/redis.conf"]
}

resource "docker_image" "redis" {
	name = "redis:latest"
}

output "redis_servers" {
	value = "${join(",", docker_container.redis-servers.*.ip_address)}"
}
/* commented out so terra doesnt delete everytime i destroy the setup.
resource "docker_image" "redis-clusterer" {
	name = "redis-clusterer:latest"
}
*/
resource "null_resource" "wait" {
	depends_on = ["docker_container.redis-servers"]
	provisioner "local-exec" {
        command = "echo 'Sleeping for 5...' && sleep 5"
    }
}

resource "docker_container" "redis-clusterer" {
	depends_on = ["docker_container.redis-servers"]
	image = "redis-clusterer:latest"
	name = "redis-setup"

	restart = "no"
	must_run = false

	command = ["create", "--unattended", "--replicas", "1", "${formatlist("%s:6379", docker_container.redis-servers.*.ip_address)}"]
}

resource "docker_container" "haproxy-redis-lb" {
	depends_on = ["docker_container.redis-servers"]

	image = "haproxy:1.5.18"
	name = "haproxy-redis-lb"

	restart = "always"

	volumes {
		container_path  = "/usr/local/etc/haproxy"
		host_path = "/home/dmportella/_workspaces/terraform/redis-cluster/config/haproxy"
		read_only = false
	}
}

resource "null_resource" "haconfig" {

	provisioner "local-exec" {
		command = "echo -n '${data.template_file.haproxy_config.rendered}' > ./config/haproxy/haproxy.cfg"
	}

	provisioner "local-exec" {
		command = "echo 'Sleeping for 5...' && sleep 5"
	}

}

data "template_file" "haproxy_config" {
	template = "${file("${path.module}/config/haproxy/haproxy.tpl")}"

	vars {
		serverNames = "${join(",", docker_container.redis-servers.*.name)}"
		serverIpAddresses = "${join(",", docker_container.redis-servers.*.ip_address)}"
	}
}