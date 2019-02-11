# Docker PHP Tutorial - Learning Docker for PHP Developers
In this tutorial I'll take you on "my" journey of learning Docker as a PHP developer. 
Since I actively use everything explained along the way (and force it upon my team ;)) I can hopefully
shed some light onto some more advanced issues like cross-OS-setups and seamless IDE integration.

Two words of caution:
- I tend to write rather lengthy, in-dept articles so you should allocate some time to work it all
through
- my main OS is Windows. Although most of the things should be easily transferable into OSX/Linux you might run into
  some quirks that I didn't encounter.

## Setup
Each tutorial is placed in a separate branch and has an accompanying article in [my blog](https://www.pascallandau.com/blog/)
I recommend to clone the full repository and check out the corresponding branch for easy reference. 

````
mkdir -p /c/codebase
cd /c/codebase/
git clone https://github.com/paslandau/docker-php-tutorial.git
cd docker-php-tutorial

git checkout part_2
````

## Tutorials
Please subscribe to my [RSS Feed](https://www.pascallandau.com/feed.xml) and/or 
[subscribe via email](https://www.pascallandau.com/blog/#newsletter) 
to be automatically notified when a new part gets published. I'll also probably brag on
[Twitter](https://twitter.com/PascalLandau) about it ;)

### Published
- [Setting up PHP, PHP-FPM and NGINX for local development on Docker](#setting-up-php-php-fpm-and-nginx-for-local-development-on-docker)
- [Setting up PhpStorm with Xdebug for local development on Docker](#setting-up-phpstorm-with-xdebug-for-local-development-on-docker)

### Planned (already used by us but not put into writing):
- [Running a complete PHP Development Environment/Infrastructure on Docker](#running-a-complete-php-development-environmentinfrastructure-on-docker)

### Roadmap (wow much want, such little time):
- [Building a CI Pipeline with Jenkins for Dockerized PHP Applications](#building-a-ci-pipeline-with-jenkins-for-dockerized-php-applications)
- [Deploying Dockerized PHP Applications via CD Pipeline with Jenkins to Production](#deploying-dockerized-php-applications-via-cd-pipeline-with-jenkins-to-production)
- [Scaling Dockerized PHP Applications with Terraform and Kubernetes on GCP/AWS](#scaling-dockerized-php-applications-with-terraform-and-kubernetes-on-gcpaws)

### Setting up PHP, PHP-FPM and NGINX for local development on Docker
- Status: published ✓
- Link: https://www.pascallandau.com/blog/php-php-fpm-and-nginx-on-docker-in-windows-10/
- Branch: [Part 1](https://github.com/paslandau/docker-php-tutorial/tree/part_1_setting-up-php-php-fpm-and-nginx-for-local-development-on-docker)

A primer on Docker. What is Docker? How to install it / transition from Vagrant?
How to interact with containers? How to organize multiple services (php-cli, php-fpm, nginx) via docker-compose? 

### Setting up PhpStorm with Xdebug for local development on Docker
- Status: published ✓
- Link: https://www.pascallandau.com/blog/setup-phpstorm-with-xdebug-on-docker/
- Branch: [Part 2](https://github.com/paslandau/docker-php-tutorial/tree/part_2_setting-up-phpstorm-with-xdebug-for-local-development-on-docker)

Using docker for Development. How to configure PhpStorm to play nicely with Docker? 
How to setup Xdebug (including the solution for the dreaded 'Connection with Xdebug was not established.' error)?

### Running a complete PHP Development Environment/Infrastructure on Docker
- Status: in the making...
- Link: [Part 3 (Draft)](https://github.com/paslandau/paslandau.github.io/blob/develop/source/_drafts/running-complete-php-development-environment-on-docker.md)
- Branch: 

Running a battle-tested development infrastructure for PHP developers in Docker.
How to organize the docker folder structure (e.g. shared scripts for containers)? 
How to set up further services like PHP worker nodes or a Blackfire profiler server? 
How to establish a convenient workflow via `make`?

### Building a CI Pipeline with Jenkins for Dockerized PHP Applications
- Status: planned
- Link: [Part 4 (Draft)](https://github.com/paslandau/paslandau.github.io/blob/develop/source/_drafts/jenkins-ci-pipeline-for-dockerized-php-applications.md)
- Branch: 

### Deploying Dockerized PHP Applications via CD Pipeline with Jenkins to Production
- Status: Wishful thinking
- Link: 
- Branch: 

### Scaling Dockerized PHP Applications with Terraform and Kubernetes on GCP/AWS
- Status: Dream Caused by the Flight of a Bee Around a Pomegranate a Second Before Awakening
- Link: 
- Branch: 