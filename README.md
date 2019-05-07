# Structuring the Docker setup for PHP Projects
See [Structuring the Docker setup for PHP Projects](https://www.pascallandau.com/blog/structuring-the-docker-setup-for-php-projects/)

Running a minimal development infrastructure for PHP developers in Docker. How to organize the docker folder structure (e.g. shared scripts for containers)? 
How to use shared configuration / scripts across multiple services? How to establish a convenient workflow via `make`?

See [the full list of tutorials in the master branch](https://github.m/paslandau/docker-php-tutorial#tutorials).

## Getting started
````
git clone https://github.com/paslandau/docker-php-tutorial.git
cd docker-php-tutorial
git checkout part_3_structuring-the-docker-setup-for-php-projects
make docker-clean
make docker-init
make docker-build-from-scratch
make docker-test
````
