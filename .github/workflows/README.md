## Make your own Docs ci build with Github Actions

NOTE: To set up your own image builds, you need to have accounts in **hud.docker.com** and **github.com**

You can create your own process for building and pushing Docker-Docs images using our github ci actions. 

To do this:

#### 1. Fork this repository

- Fork this repository to your account.

#### 2. Enable actions

- Follow to the tab of actions in forked repository and enable them.

#### 3. Set-up resository action variables and secrets

Follow to:

Settings --> Secrets and Variables --> Actions --> Variables --> Repository Variables

- Add variable with name `DOCKER_ORG` 

The variable value should contain your account in hub.docker which will be used when pushing images in the tag, for example, if the variable value is `onlyoffice`, the images will be push to:

`docker.io/onlyoffice/docs-docservice-<specifyed_edition>:<some_version>`

Also please add two repository secrets for login in hub.docker:

- `DOCKER_HUB_USERNAME` - Stored your user name that will push images.

- `DOCKER_HUB_ACCESS_TOKEN` - Stored your account user token.

#### 4. Use multi-arch build action to make your own images

After repository setting up is finished, you can make your own images. Follow this steps:

- Navigate to Actions tab.
- Select the action named `Multi-arch build`.
- Click `Run workflow` to display the build configuration window.

Configure build:

- Select the image architecture, by default both (amd64/arm64) are built.
- Select Docs editions, set `ee,de` if you need build both editions (Field can be empty if you dont need build Docs).
- Select Docs-non-plugins if needed, that will build images without plugins.
- Select Docs-utils if needed.
- Select Docs-balancer if needed.
- Specify tag (required field).
- Set `Push to test-repo` to 'false'.
- Set Docs version that will be installed inside images (empty by default = latest released Docs version).
- Set `Get packages from:` to prod.

Thats all, then run configured workflow.

If you configure action as described in this instruction, you got:

- `docker.io/<your_company>/docs-docservice-ee:<specifyed_tag>`
- `docker.io/<your_company>/docs-converter-ee:<specifyed_tag>`
- `docker.io/<your_company>/docs-proxy-ee:<specifyed_tag>`
- `docker.io/<your_company>/docs-docservice-de:<specifyed_tag>`
- `docker.io/<your_company>/docs-converter-de:<specifyed_tag>`
- `docker.io/<your_company>/docs-proxy-de:<specifyed_tag>`
- `docker.io/<your_company>/docs-docservice-de:<specifyed_tag>-noplugins`
- `docker.io/<your_company>/docs-converter-de:<specifyed_tag>-noplugins`
- `docker.io/<your_company>/docs-proxy-de:<specifyed_tag>-noplugins`
- `docker.io/<your_company>/docs-balancer:<specifyed_tag>`
- `docker.io/<your_company>/docs-example:<specifyed_tag>`
- `docker.io/<your_company>/docs-utils:<specifyed_tag>`
