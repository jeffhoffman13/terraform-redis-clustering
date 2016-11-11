# terraform-redis-clustering
A quick example for setting up Redis cluster with HAProxy TCP load balancing.

## Terraform

Check everything is oke.

`terraform plan`

Apply changes.

`terraform apply`

# Setup Includes

* 3 redis master nodes and 3 replicas
* HAProxy for redis load balancing 
* custom docker container to run the redis-trib tool to set up the cluster. (this is a modifed version of it to allow unattended install)
  * Ticket (https://github.com/antirez/redis/issues/3143) PR (https://github.com/antirez/redis/pull/3602)

All nodes can be scaled up or down.

> *Note*: please ensure change the volumes locations before running
> Also bear in mind that the way the config files are rendered the `\r\n` dont get escaped properly so if haproxy is not work just make sure it matches the tpl file. I am working on a solution for that.