#!/bin/sh

function service_info(){
    service=$1
    echo ""
    echo -e "Testing service '\e[1m$service\e[0m'"
    echo "======="
}

function assert_result(){
    if [[ "$1" == true ]];
    then
        echo -e "\e[32;1mOK\e[0m"
    else
        echo -e "\e[31;1mERROR\e[0m"
    fi;
}

function docker_exec(){
    service=$1
    shift;
    docker exec $(docker ps --filter name=${service} -q | head -1) "$@"
}

function test_container_is_running(){
    service=$1
    result=false
    echo "Checking if '${service}' has a running container"
    echo "$(docker ps --filter name=${service})" | grep -q "${service}" && result=true
    assert_result ${result}
}

function test_host_docker_internal(){
    service=$1
    result=false
    echo "Checking 'host.docker.internal' on '${service}'"
    docker_exec ${service} dig host.docker.internal | grep -vq NXDOMAIN && result=true
    assert_result ${result}
}

function test_request_nginx(){
    url=$1
    expected=$2
    result=false
    echo "Sending request to nginx via '$url' and expect to see '${expected}'"
    curl -s ${url} | grep -q "${expected}" && result=true
    assert_result ${result}
}

function test_php_version(){
    service=$1
    php=$2
    version=$3
    expected="PHP $version"
    result=false
    echo "Testing PHP version '$version' on '$service' for '$php' and expect to see '${expected}'"
    docker_exec ${service} php -v | grep -q "${expected}" && result=true
    assert_result ${result}
}

function test_php_modules(){
    service=$1
    php=$2
    shift;
    shift;
    for module in "$@"; do
        test_php_module ${service} ${php} "${module}"
    done

}

function test_php_module(){
    service=$1
    php=$2
    module=$3
    expected="$module"
    result=false
    echo "Testing PHP module '${expected}' on '$service' for '$php'"
    docker_exec ${service} php -m | grep -q "${expected}" && result=true
    assert_result $result
}

service="workspace"
service_info ${service}
test_container_is_running ${service}
test_php_version ${service} php 7.3
test_php_modules ${service} php xdebug "Zend OPcache"
test_host_docker_internal ${service}

service="php-fpm"
service_info ${service}
test_container_is_running ${service}
test_php_version ${service} php-fpm 7.3
test_php_modules ${service} php-fpm xdebug "Zend OPcache"
test_host_docker_internal ${service}

service="nginx"
service_info ${service}
test_container_is_running ${service}
test_request_nginx 127.0.0.1 "Hello world"
