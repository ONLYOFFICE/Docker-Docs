## buildx bake configurations ###
variable "TAG" {
    default = "latest" 
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
    target = "proxy"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test:${TAG}"]
}

target "converter" {
    target = "converter"  
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test:${TAG}"] 
}

target "docservice" {
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-test${PRODUCT_EDITION}:${TAG}"]
    target = "docservice"
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}
