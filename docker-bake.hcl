
variable "DOCKER_TAG" {
    default = "latest" 
}

variable "COMPANY_NAME" { 
    default = "onlyoffice" 
}

group "apps" {
    targets = ["proxy", "converter", "docservice"]
}

target "proxy" {
    tags = ["docker.io/${COMPANY_NAME}/docs-test:${DOCKER_TAG}"]
}

target "converter" { 
    tags = ["docker.io/${COMPANY_NAME}/docs-test:${DOCKER_TAG}"] 
}

target "docservice" {
    tags = ["docker.io/${COMPANY_NAME}/docs-test:${DOCKER_TAG}"]
