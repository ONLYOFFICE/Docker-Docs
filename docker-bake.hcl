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

variable "EXAMPLE_PATH" {
    default = "document-server-integration/web/documentserver-example/"
}

group "apps" {
    targets = ["proxy", "converter", "docservice", "example"]
}

target "example" {
    target = "proxy"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-example${PRODUCT_EDITION}:${TAG}"]
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}

target "proxy" {
    target = "proxy"
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-proxy${PRODUCT_EDITION}:${TAG}"]
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}

target "converter" {
    target = "converter"  
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-converter${PRODUCT_EDITION}:${TAG}"] 
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}

target "docservice" {
    target = "docservice" 
    tags = ["docker.io/${COMPANY_NAME}/${PREFIX_NAME}-docservice${PRODUCT_EDITION}:${TAG}"]
    args = {
        PRODUCT_EDITION = PRODUCT_EDITION
    }
}
