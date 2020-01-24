COMPANY_NAME ?= onlyoffice
GIT_BRANCH ?= develop
PRODUCT_NAME ?= documentserver-ie
PRODUCT_VERSION ?= 0.0.0
BUILD_NUMBER ?= 0

PACKAGE_VERSION := $(PRODUCT_VERSION)-$(BUILD_NUMBER)

PRODUCT_URL := "http://repo-doc-onlyoffice-com.s3-eu-west-1.amazonaws.com/centos/7/$(COMPANY_NAME)-$(PRODUCT_NAME)/$(GIT_BRANCH)/$(PACKAGE_VERSION)/$(COMPANY_NAME)-$(PRODUCT_NAME)-$(PACKAGE_VERSION).x86_64.rpm"

UPDATE_LATEST := false

ifneq (,$(findstring develop,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
DOCKER_TAGS += latest
else ifneq (,$(findstring release,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
else ifneq (,$(findstring hotfix,$(GIT_BRANCH)))
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))
else
DOCKER_TAGS += $(subst -,.,$(PACKAGE_VERSION))-$(subst /,-,$(GIT_BRANCH))
endif

DOCKER_REPO = $(subst -,,$(COMPANY_NAME))/4testing-$(PRODUCT_NAME)-base

COLON := __colon__
DOCKER_TARGETS := $(foreach TAG,$(DOCKER_TAGS),$(DOCKER_REPO)$(COLON)$(TAG))

.PHONY: all clean clean-docker deploy docker

$(DOCKER_TARGETS): $(DEB_REPO_DATA)

	sudo docker build --build-arg PRODUCT_URL=$(PRODUCT_URL) --build-arg COMPANY_NAME=$(COMPANY_NAME) -t $(subst $(COLON),:,$@) . &&\
	mkdir -p $$(dirname $@) &&\
	echo "Done" > $@

all: $(DOCKER_TARGETS)

clean:
	rm -rfv $(DOCKER_TARGETS)
		
clean-docker:
	sudo docker rmi -f $$(sudo docker images -q $(COMPANY_NAME)/*) || exit 0

deploy: $(DOCKER_TARGETS)
	$(foreach TARGET,$(DOCKER_TARGETS),sudo docker push $(subst $(COLON),:,$(TARGET));)
