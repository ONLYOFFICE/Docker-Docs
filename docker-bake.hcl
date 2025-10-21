## buildx bake configurations ###
variable "TAG" {
    default = "" 
}

variable "COMPANY_NAME" { 
    default = "onlyoffice" 
}

variable "PREFIX_NAME" { 
    default = ""
} 

variable "PRODUCT_EDITION" {
    default = ""
}

variable "DOCKERFILE" {
    default = "Dockerfile"
}

variable "NOPLUG_POSTFIX" {
    default = ""
}

variable "DS_VERSION_HASH" {
    default = ""
}

variable "REGISTRY" {
    default = "docker.io"
}

variable "PRODUCT_BASEURL" {
    default = "https://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver"
}

variable "RELEASE_VERSION" {
    default = ""
}

variable "PLATFORM" {
    default = ""
}

group "apps" {
    targets = ["proxy", "converter", "docservice", "example"]
}

target "example" {
    target = "example"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-example:${TAG}"] : [
                                          "${REGISTRY}/docs-example:${TAG}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "adminpanel" {
    target = "adminpanel"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-adminpanel${PRODUCT_EDITION}:${TAG}"] : [
                                          "${REGISTRY}/docs-adminpanel${PRODUCT_EDITION}:${TAG}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "PRODUCT_BASEURL": "${PRODUCT_BASEURL}"
        "RELEASE_VERSION": "${RELEASE_VERSION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
    }
}

target "proxy" {
    target = "proxy"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-proxy${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"] : [
                                          "${REGISTRY}/docs-proxy${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
        "PRODUCT_BASEURL": "${PRODUCT_BASEURL}"
        "RELEASE_VERSION": "${RELEASE_VERSION}"
    }
}

target "converter" {
    target = "converter"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-converter${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"] : [
                                          "${REGISTRY}/docs-converter${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
        "PRODUCT_BASEURL": "${PRODUCT_BASEURL}"
        "RELEASE_VERSION": "${RELEASE_VERSION}"
    }
}

target "docservice" {
    target = "docservice"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-docservice${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"] : [
                                          "${REGISTRY}/docs-docservice${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
        "PRODUCT_BASEURL": "${PRODUCT_BASEURL}"
        "RELEASE_VERSION": "${RELEASE_VERSION}"
    }
}

target "utils" {
    target = "utils"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-utils:${TAG}"] : [
                                          "${REGISTRY}/docs-utils:${TAG}" ]
    platforms = ["${PLATFORM}"]
    args = {
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
        "PRODUCT_BASEURL": "${PRODUCT_BASEURL}"
        "RELEASE_VERSION": "${RELEASE_VERSION}"
    }
}

target "balancer" {
    target = "balancer"
    dockerfile = "${DOCKERFILE}"
    tags = equal("docker.io",REGISTRY) ? ["${REGISTRY}/${COMPANY_NAME}/${PREFIX_NAME}docs-balancer:${TAG}"] : [
                                          "${REGISTRY}/docs-balancer:${TAG}" ]
    platforms = ["${PLATFORM}"]
}

