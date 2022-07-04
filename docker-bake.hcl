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

group "apps" {
    targets = ["proxy", "converter", "docservice", "example"]
}

target "example" {
    target = "example"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-example${PRODUCT_EDITION}:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "proxy" {
    target = "proxy"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-proxy${PRODUCT_EDITION}:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "converter" {
    target = "converter"  
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-converter${PRODUCT_EDITION}:${TAG}"] 
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "docservice" {
    target = "docservice" 
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-docservice${PRODUCT_EDITION}:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        "PRODUCT_EDITION": "${PRODUCT_EDITION}"
    }
}

target "utils" {
    target = "utils"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-utils:${TAG}"]
    platforms = ["linux/amd64", "linux/arm64"]
}

