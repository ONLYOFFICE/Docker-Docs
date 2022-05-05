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
    targets = ["proxy", "converter", "docservice"]
}

target "proxy" {
    dockerfile = "Dockerfile.multiarch"
    target = "proxy"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-proxy${PRODUCT_EDIDION}:${TAG}"]
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}

target "converter" {
    dockerfile = "Dockerfile.multiarch"
    target = "converter"  
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-converter${PRODUCT_EDITION}:${TAG}"] 
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}

target "docservice" {
    dockerfile = "Dockerfile.multiarch"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-docservice${PRODUCT_EDITION}:${TAG}"]
    target = "docservice"
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}
