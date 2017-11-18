# Lambdas-sky

Golo serverless platform


## Golo function management

- You need to setup a GitHub Repository: so you will able to version your Golo functions
  - ⚠️ you can use instead [GitBucket](https://gitbucket.github.io/), very useful if you want to experiment locally. GitBuket provides a GitHub compliant API (see `install-gitbucket.sh`, then run it `java -jar gitbucket/gitbucket.war`. admin user: `root/root`)
  - 🚧 GitLab support in progress 

## Setup of Lambdas-sky


## Setup of GitBucket/GitHub

- Add a webhook:
  - if your Lambdas-Sky server listening on `http://mini-me:9090` then use:
    - Payload url: `http://mini-me:9090/hey`
    - Content type: `application/json`
    -events: `Pull request`, `Push`
- generate a personal web token

## Start Lambdas Sky

See `start.sh`

```bash
PORT=9090 TOKEN="hello" API="hello" CREDENTIALS="hello" golo golo --classpath jars/*.jar --files main.golo
```