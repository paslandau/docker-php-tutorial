<div align=center>


![Docker PHP Tutorial](https://www.pascallandau.com/img/docker-php-tutorial.png)


</div>

---

# Docker PHP Tutorial - Learning Docker for PHP Developers

In this tutorial I'll take you on "my" journey of learning Docker as a PHP developer. Since I
actively use everything explained along the way (and force it upon my team ;)) I can hopefully shed
some light onto some more advanced issues like cross-OS-setups and seamless IDE integration.

Two words of caution:

- I tend to write rather lengthy, in-depth articles, so you should allocate some time to work it all
  through
- my main OS is Windows. Although most of the things should be easily transferable into OSX/Linux
  you might run into some quirks that I didn't encounter.

You can also find an overview of the published articles at the
[Docker PHP Tutorial](https://www.pascallandau.com/docker-php-tutorial/) site of my homepage.

## Setup

Each tutorial is placed in a separate branch and has an accompanying article
in [my blog](https://www.pascallandau.com/blog/)
I recommend cloning the full repository and check out the corresponding branch for easy reference.
Example:

````
mkdir -p /c/codebase
cd /c/codebase/
git clone https://github.com/paslandau/docker-php-tutorial.git
cd docker-php-tutorial

git checkout part_2_setting-up-phpstorm-with-xdebug-for-local-development-on-docker
````

## Tutorials

Please subscribe to my [RSS Feed](https://www.pascallandau.com/feed.xml) and/or
[subscribe via email](https://www.pascallandau.com/blog/#newsletter)
to be automatically notified when a new part gets published. I'll also probably brag about it on
[Twitter](https://twitter.com/PascalLandau) ;)

### Playlist

There a 
[YouTube playlist](https://www.youtube.com/watch?v=YYI5mTjFDuA&list=PLScVLZNShARRTO-ebug0yzbiXDxtw0rtg) 
available containing all videos of the tutorial series.

### Published

- [Setting up PHP, PHP-FPM and NGINX for local development on Docker](#setting-up-php-php-fpm-and-nginx-for-local-development-on-docker)
- [Setting up PhpStorm with Xdebug for local development on Docker](#setting-up-phpstorm-with-xdebug-for-local-development-on-docker)
- [Structuring the Docker setup for PHP Projects](#structuring-the-docker-setup-for-php-projects)
- [Docker from scratch for PHP 8.1 Applications in 2022](#docker-from-scratch-for-php-81-applications-in-2022)
- [PhpStorm, Docker and Xdebug 3 on PHP 8.1 in 2022](#phpstorm-docker-and-xdebug-3-on-php-81-in-2022)
- [Run Laravel 9 on Docker in 2022](#run-laravel-9-on-docker-in-2022)
- [Set up PHP QA tools and control them via make](#set-up-php-qa-tools-and-control-them-via-make)
- [Use git-secret to encrypt secrets in the repository](#use-git-secret-to-encrypt-secrets-in-the-repository)
- [Create a CI pipeline for dockerized PHP Apps](#create-a-ci-pipeline-for-dockerized-php-apps)
- [A primer on GCP Compute Instance VMs for dockerized Apps](#a-primer-on-gcp-compute-instance-vms-for-dockerized-apps)
- [Deploy dockerized PHP Apps to production on GCP via `docker compose`](#deploy-dockerized-php-apps-to-production-on-gcp-via-docker-compose)
- [Create a production infrastructure for dockerized PHP Apps on GCP](#create-a-production-infrastructure-for-dockerized-php-apps-on-gcp)
- [Deploy dockerized PHP Apps to production](#deploy-dockerized-php-apps-to-production)
- [Use the `gcloud` cli docker image instead of installing it locally](#use-the-gcloud-cli-docker-image-instead-of-installing-it-locally)
- [Manage Logfiles in Docker via Volumes and Sidecar containers](#manage-logfiles-in-docker-via-volumes-and-sidecar-containers)

### Planned (already used by us but not put into writing):

- [Deploy dockerized PHP Apps on a GCP VM](#deploy-dockerized-php-apps-on-a-gcp-vm)

### Roadmap (wow much want, such little time):

- [Scaling Dockerized PHP Applications with Kubernetes on GCP](#scaling-dockerized-php-applications-with-kubernetes-on-gcp)

### Setting up PHP, PHP-FPM and NGINX for local development on Docker

- Status: published ✓
- Link: https://www.pascallandau.com/blog/php-php-fpm-and-nginx-on-docker-in-windows-10/
- Branch:
  [Part 1](https://github.com/paslandau/docker-php-tutorial/tree/part_1_setting-up-php-php-fpm-and-nginx-for-local-development-on-docker)

A primer on Docker. What is Docker? How to install it / transition from Vagrant? How to interact
with containers? How to organize multiple services (php-cli, php-fpm, nginx) via docker-compose?

### Setting up PhpStorm with Xdebug for local development on Docker

- Status: published ✓
- Link: https://www.pascallandau.com/blog/setup-phpstorm-with-xdebug-on-docker/
- Branch: 
  [Part 2](https://github.com/paslandau/docker-php-tutorial/tree/part_2_setting-up-phpstorm-with-xdebug-for-local-development-on-docker)

Using docker for Development. How to configure PhpStorm to play nicely with Docker? How to setup
Xdebug (including the solution for the dreaded 'Connection with Xdebug was not established.' error)?

### Structuring the Docker setup for PHP Projects

- Status: published ✓
- Link: https://www.pascallandau.com/blog/structuring-the-docker-setup-for-php-projects/
- Branch: 
  [Part 3](https://github.com/paslandau/docker-php-tutorial/tree/part_3_structuring-the-docker-setup-for-php-projects)

Running a battle-tested development infrastructure for PHP developers in Docker. How to organize the
docker folder structure (e.g. shared scripts for containers)? How to establish a convenient workflow
via `make`?

### Docker from scratch for PHP 8.1 Applications in 2022

- Status: published ✓
- Link: https://www.pascallandau.com/blog/docker-from-scratch-for-php-applications-in-2022/
- Branch:
  [Part 4.1](https://github.com/paslandau/docker-php-tutorial/tree/part-4-1-docker-from-scratch-for-php-applications-in-2022)

An update of the previous article (Part 3) with the learnings of the past 3 years:
- simplify the setup
- add more containers (redis, mysql, workers)
- prepare for additional environments (CI, production)

### PhpStorm, Docker and Xdebug 3 on PHP 8.1 in 2022

- Status: published ✓
- Link: https://www.pascallandau.com/blog/phpstorm-docker-xdebug-3-php-8-1-in-2022/
- Branch:
  [Part 4.2](https://github.com/paslandau/docker-php-tutorial/tree/part-4-2-phpstorm-docker-xdebug-3-php-8-1-in-2022)

An update of the previous article on setting up PhpStorm (Part 2) using the latest PHP version 
(PHP 8.1) as well as the latest Xdebug version (3). The article also covers additional debugging 
challenges (from the browser, from the CLI, from a long-running worker process).

### Run Laravel 9 on Docker in 2022

- Status: published ✓
- Link: https://www.pascallandau.com/blog/run-laravel-9-docker-in-2022/
- Branch:
  [Part 4.3](https://github.com/paslandau/docker-php-tutorial/tree/part-4-3-run-laravel-9-docker-in-2022)

A step-by-step walk through to set up a new Laravel 9 project on the docker setup of this 
tutorial, using a couple of common Laravel components (Commands, Controllers, Queues, Databases).

### Set up PHP QA tools and control them via make

- Status: published ✓
- Link: https://www.pascallandau.com/blog/php-qa-tools-make-docker/
- Branch:
  [Part 5](https://github.com/paslandau/docker-php-tutorial/tree/part-5-php-qa-tools-make-docker)

Set up some PHP QA tools like `phpcs`, `phpstan`, etc. in the dockerized PHP application and 
provide `make` targets to run them either in parallel or individually.

### Use `git secret` to encrypt secrets in the repository

- Status: published ✓
- Link: https://www.pascallandau.com/blog/git-secret-encrypt-repository-docker/
- Branch:
  [Part 6](https://github.com/paslandau/docker-php-tutorial/tree/part-6-git-secret-encrypt-repository-docker)

Set up `git secret` to encrypt and store secrets directly in a git repository. All required 
tools are set up in Docker and their usage is defined via `make` targets.

### Create a CI pipeline for dockerized PHP Apps

- Status: published ✓
- Link: https://www.pascallandau.com/blog/ci-pipeline-docker-php-gitlab-github/
- Branch:
  [Part 7](https://github.com/paslandau/docker-php-tutorial/tree/part-7-ci-pipeline-docker-php-gitlab-github)

Create a CI pipeline using the dockerized setup introduced in the previous tutorial that can be 
executed on any CI provider. Concrete examples for Gitlab Pipelines and Github actions are included.

### A primer on GCP Compute Instance VMs for dockerized Apps

- Status: published ✓
- Link: https://www.pascallandau.com/blog/gcp-compute-instance-vm-docker/
- Branch:
  [Part 8](https://github.com/paslandau/docker-php-tutorial/tree/part-8-gcp-compute-instance-vm-docker)

Getting started with the Google Cloud Platform (GCP) as infrastructure provider for a container
registry to push and pull docker images as well as for virtual machines to run dockerized
applications.

### Deploy dockerized PHP Apps to production on GCP via docker compose

- Status: published ✓
- Link: https://www.pascallandau.com/blog/deploy-docker-compose-php-gcp-poc/
- Branch:
  [Part 9](https://github.com/paslandau/docker-php-tutorial/tree/part-9-deploy-docker-compose-php-gcp-poc)

Introduce a `prod` environment to build docker images that are then deployed "to production" on a
GCP VM to be executed via `docker compose` as a proof-of-concept.

### Create a production infrastructure for dockerized PHP Apps on GCP

- Status: published ✓
- Link: https://www.pascallandau.com/blog/create-production-infrastructure-php-app-gcp/
- Branch:
  [Part 10](https://github.com/paslandau/docker-php-tutorial/tree/part-10-create-production-infrastructure-php-app-gcp)

Create a production infrastructure for a dockerized PHP application on GCP using multiple VMs 
and managed services for `redis` and `mysql`.

### Deploy dockerized PHP Apps to production

- Status: published ✓
- Link: https://www.pascallandau.com/blog/deploy-dockerized-php-app-production/
- Branch:
  [Part 11](https://github.com/paslandau/docker-php-tutorial/tree/part-11-deploy-dockerized-php-app-production)

Deploy a dockerized PHP application to a production environment on GCP using multiple VMs and 
run it via "plain" `docker` (without `compose`).

### Use the `gcloud` cli docker image instead of installing it locally

- Status: published ✓
- Link: https://www.pascallandau.com/blog/use-gcloud-cli-docker-image/
- Branch:
  [Part 12](https://github.com/paslandau/docker-php-tutorial/tree/part-12-use-gcloud-cli-docker-image)

Replace the locally installed `gcloud` cli tool with the official `gcloud` cli docker image and 
integrate it in the setup and deployment process.

### Manage Logfiles in Docker via Volumes and Sidecar containers

- Status: published ✓
- Link: https://www.pascallandau.com/blog/manage-log-files-in-docker-via-volumes-and-sidecar-containers-with-cron-jobs-and-logrotate/
- Branch:
  [Part 13](https://github.com/paslandau/docker-php-tutorial/tree/part-13-manage-log-files-in-docker-via-volumes-and-sidecar-containers-with-cron-jobs-and-logrotate)

Implement the sidecar pattern to manage the  various log files of our dockerized application via 
`logrotate` and `cron`.

