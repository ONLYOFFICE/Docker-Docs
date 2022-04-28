## variables for buildx bake ##
variable "DOCKER_TAG" {
    default = "latest" 
}

variable "COMPANY_NAME" { 
    default = "onlyoffice" 
}

variable "PREFIX_NAME" { 
    defaule = "docs-test"
} 

group "apps" {
    targets = ["proxy", "converter", "docservice"]
}

target "proxy" {
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test:${DOCKER_TAG}"]
}

target "converter" { 
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test:${DOCKER_TAG}"] 
}

target "docservice" {
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test:${DOCKER_TAG}"]
