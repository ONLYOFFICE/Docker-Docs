## buildx bake configurations ###
variable "TAG" {
    default = "" 
}

variable "COMPANY_NAME" { 
    default = "onlyoffice" 
}

variable "PREFIX_NAME" { 
    default = "docs"
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

group "apps" {
    targets = ["proxy", "converter", "docservice", "example"]
}

target "example" {
    target = "example"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-example${PRODUCT_EDITION}:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "proxy" {
    target = "proxy"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-proxy${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
    }
}

target "converter" {
    target = "converter"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-converter${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
    }
}

target "docservice" {
    target = "docservice"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-docservice${PRODUCT_EDITION}:${TAG}${NOPLUG_POSTFIX}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
    }
}

target "utils" {
    target = "utils"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-utils:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "DS_VERSION_HASH": "${DS_VERSION_HASH}"
    }
}

target "balancer" {
    target = "balancer"
    dockerfile = "${DOCKERFILE}"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-balancer:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
}

