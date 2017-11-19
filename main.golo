module lambdassky

#import java.lang.Thread

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

import gololang.Errors
import gololang.concurrent.workers.WorkerEnvironment
import spark.Spark

import dvcs

augment spark.Response {
  function json = |this, content| {
    this: type("application/json;charset=UTF-8")
    return JSON.stringify(content)
  }
  function text = |this, content| {
    this: type("text/plain;charset=UTF-8")
    return content
  }
}

augment spark.Request {
  function bodyToDynamicObject = |this| -> JSON.toDynamicObjectFromJSONString(this: body())
}

# comment gérer les imports? si plusieurs (multiples calls)
# let env = gololang.EvaluationEnvironment()

struct lambda = {
  name,
  path,
  branch,
  owner,
  repository,
  code,
  imports,
  description,
  timeout
}

struct serverConfig = {
  port,
  token,
  api,
  credentials
}

function log = |txt, args...| -> println(java.text.MessageFormat.format(txt, args))

function executeConcurrentLambda = |lambda, parameters| {
  return trying({
    let executor = Executors.newSingleThreadExecutor()
    let future = executor: submit(asInterfaceInstance(java.util.concurrent.Callable.class, {
      return lambda: code()(parameters)
    }))
    let res = future: get(lambda: timeout(), MILLISECONDS())
    executor: shutdown()  
    return res
  })
}

function searchValueInComments = |constantName, source| -> trying(-> 
  source: split("#")
        : asList()
        : find(|item| -> item: contains(constantName+"=") == true)
        : trim()
        : split("="): get(1): split("\n"): get(0)
)


function defineRoutes = |config| {
  port(config: port())
  externalStaticFileLocation(currentDir()+"/public")

  let dvcs = dvcs.Client(
    uri= config: api(),
    token= config: token()
  )

  let lambdasMap = map[]
  let envWorkers = WorkerEnvironment.builder(): withCachedThreadPool()
  let envEvaluations = gololang.EvaluationEnvironment()

  # fetch tle lambdas list
  get("/lambdas", |request, response| -> # return is implicit
    trying(-> lambdasMap)
      : either(
        recover= |error| {
          response: status(505)
          log("😡 {0}", error: message())
          return response: json(DynamicObject(): error(error: message()))
        },
        mapping= |lambdas| { 
          response: status(201)
          return response: json(lambdas)
        }
      )
  )

  post("/tests", |request, response| {
    log("❇️ body: {0}", request: body())
    let data =  JSON.toDynamicObjectFromJSONString(request: body())
    return response: json(DynamicObject(): message("hello from tests"))
  })

  # execute a lambdas
  post("/lambdas", |request, response| {
    # TODO: make a try
    # TODO: use credentials
    # TODO: use a worker or a promise
    # TODO: detect if the execution is too long
    # TODO: check data
    
    let computation = trying({
      # branch+"|"+owner+"/"+repositoryName+"/"+commit: path()
      log("❇️ body: {0}", request: body())
      let data =  JSON.toDynamicObjectFromJSONString(request: body())
      let lambdaKey = data: branch()+"|"+data: owner()+"/"+data: repository()+"/"+data: path()
      let parameters = data: parameters()

      log("❇️ lambdaKey: {0}", lambdaKey)
      log("❇️ parameters: {0}", parameters)
      
      let lambdaToExecute = Option(lambdasMap: get(lambdaKey))

      let resultOfCall = lambdaToExecute: either(
        default= { # lambda is null, so not loade in memory
          # try to get the lambda on the dvcs
          log("⚠️ lambda: {0}", "not in memory")

          let path = match {
            when data: branch(): equals("master") then data: path()
            otherwise data: path() + "?ref=" + data: branch()
          }

          log("❇️ path: {0}", path)

          let commit = dvcs: fetchContent(
            path= path,
            owner= data: owner(),
            repository= data: repository(),
            decode=true
          )

          log("👋 code: {0}", commit: content())

          let timeout = searchValueInComments("MAX_TIMEOUT", commit: content()): either(
            recover= |error| -> 5000_L,
            mapping = |value| -> java.lang.Long.parseLong(value)
          )
          log("⏱ timeout: {0}", timeout)     

          let description = searchValueInComments("DESCRIPTION", commit: content()): either(
            recover= |error| -> "no description",
            mapping = |value| -> value
          )
          log("📕 description: {0}", description)           

          let lambdaToAdd = lambda(
            name= commit: name(),
            path= commit: path(),
            owner= data: owner(),
            repository= data: repository(),
            branch= data: branch(),
            code= envEvaluations: def(commit: content()),
            imports= [],
            description= description,
            timeout= timeout
          )

          lambdasMap: add(
            data: branch()+"|"+data: owner()+"/"+data: repository()+"/"+commit: path(),
            lambdaToAdd
          )
          #----------------------------------------------------------------------
          # 👋 NOTE: execution
          let res = executeConcurrentLambda(lambdaToAdd, parameters)
            : either(
              recover= |error| { 
                #log("😡 with computation {0}", error)
                return DynamicObject(): error(error: toString())
              },
              mapping= |computationResult| {
                #log("❤️ currently all is ok, result is: {0}", computationResult)
                return DynamicObject(): computationResult(computationResult)
              }
            )
          log("🤖 result: {0}", res)
          return res
          #----------------------------------------------------------------------
        },
        mapping= |lambda| { # all is ok, execute the lambda and return a value
          log("😀 lambda: {0}", "in memory")
          #----------------------------------------------------------------------
          # 👋 NOTE: execution
          let res = executeConcurrentLambda(lambda, parameters)
            : either(
              recover= |error| { 
                #log("😡 with computation {0}", error)
                return DynamicObject(): error(error: toString())
              },
              mapping= |computationResult| {
                #log("❤️ currently all is ok, result is: {0}", computationResult)
                return DynamicObject(): computationResult(computationResult)
              }
            )
          log("🤖 result: {0}", res)
          return res
          #----------------------------------------------------------------------
        }
      ) # end of either option
      return resultOfCall
    })
    : either(
      recover= |error| { 
        response: status(505)
        log("😡 something wrong {0}", error)
        return DynamicObject(): error(error: toString())
      },
      mapping= |res| {
        # could be an error
        match {
          when res: computationResult() isnt null then log("❤️ currently all is ok, result is: {0}", res: computationResult())
          when res: error() isnt null then log("😡 currently all is ko, error is: {0}", res: error())
          otherwise log("🤔 well, result is: {0}", res: computationResult())
        }
        #log("❤️ currently all is ok, result is: {0}", res: computationResult())
        response: status(201)
        # this (res) is a DynamicObject 
        return res 
      }
    ) # end of either trying
    
    # NOTE that's the end
    return response: json(computation)
  })

  # https://github.com/wey-yu/poks-server/blob/master/src/main/golo/main.golo
  #{"informations": {"code": 1234, "remark": "hello world"}}  
  post("/hey", |request, response| {
    # TODO: make a try
    # TODO: use credentials

    let eventName = request: headers("X-GitHub-Event")
    
    println("=============================")
    println(" " + eventName)
    println("=============================")

    if eventName: equals("push") {
      #println(request: body())
      let data =  JSON.toDynamicObjectFromJSONString(request: body())
      let owner = data: repository(): owner(): login() #TODO check that is the same with GitHub
      let repositoryName = data: repository(): name()

      let ref = data: ref() # branch
      let sha = data: head_commit(): id()
      let branch = ref: split("refs/heads/"):get(1)

      log("ref: {0} sha: {1}", ref, sha)
      log("DVCS Event: {0} on {1}/{2}", eventName, owner, repositoryName)

      log("Committer: {0} on {1}", data: head_commit(): committer(): name(), data: head_commit(): committer(): date()) #TODO check that is the same with GitHub
      log("Message: {0}", data: head_commit(): message())

      log("added: {0} {1}", data: head_commit(): added(), data: head_commit(): added(): size())
      log("modified: {0} {1}", data: head_commit(): modified(), data: head_commit(): modified(): size())
      log("removed: {0} {1}", data: head_commit(): removed(), data: head_commit(): removed(): size())

      # TODO: for each arrays and each item: get the code
      # NOTE: be careful of branches name

      let recordCommitContent = |action, item| {
        log("👋 [{0}] item: {1} branch: {2}", action, item, branch)

        #var path = item
        #if branch: equals("master") is false {
        #  path = path + "?ref=" + branch
        #}

        let path = match {
          when branch: equals("master") then item
          otherwise item + "?ref=" + branch
        }

        let commit = dvcs: fetchContent(
          path= path,
          owner= owner,
          repository= repositoryName,
          decode=true
        )

        log("  ℹ️ name: {0}", commit: name())
        log("  ℹ️ path: {0}", commit: path())
        log("  ℹ️ type: {0}", commit: type())
        log("  ℹ️ sha: {0}", commit: sha())

        let timeout = searchValueInComments("MAX_TIMEOUT", commit: content()): either(
          recover= |error| -> 5000_L,
          mapping = |value| -> java.lang.Long.parseLong(value)
        )
        log("⏱ timeout: {0}", timeout)     

        let description = searchValueInComments("DESCRIPTION", commit: content()): either(
          recover= |error| -> "no description",
          mapping = |value| -> value
        )
        log("📕 description: {0}", description)  


        # eg: sandbox|k33g/pony/blue/hello.golo

        lambdasMap: add(
          branch+"|"+owner+"/"+repositoryName+"/"+commit: path(),
          lambda(
            name= commit: name(),
            path= commit: path(),
            owner= owner,
            repository= repositoryName,
            branch= branch,
            code= envEvaluations: def(commit: content()),
            imports= [],
            description= description,
            timeout= timeout
          )
        )

        println("---[source code]------------------------------------")
        println(commit: content())
        println("----------------------------------------------------")

      }

      data: head_commit(): modified(): each(|item| -> recordCommitContent("modified", item))
      
      data: head_commit(): added(): each(|item| -> recordCommitContent("added", item))

      data: head_commit(): removed(): each(|item| {
        # TODO
        println(item)
      })
    }

    response: status(201)
    
    return response: json(DynamicObject(): message("OK"))
  })

  println("🌍 Lambdas-Sky server is listening on " + config: port() + "... 👋")

}

----
# GitBucket API:
- documentation: https://github.com/gitbucket/gitbucket/wiki/API-WebHook
----
function main = |args| {

  if (System.getenv(): get("PORT") is null) { raise("😡 no http port") }
  if (System.getenv(): get("TOKEN") is null) { raise("😡 no token") }
  if (System.getenv(): get("API") is null) { raise("😡 no token") }

  #if (System.getenv(): get("CREDENTIALS") is null) { raise("😡 no server credential") }
  
  trying({
    let port =  Integer.parseInt(System.getenv(): get("PORT"))

    return serverConfig(
      port= port,
      token= System.getenv(): get("TOKEN"),
      api= System.getenv(): get("API"),
      credentials= System.getenv(): get("CREDENTIALS")
    )
  })
  : either(
    |config| -> defineRoutes(config),
    |error| -> log("😡 when starting Lambdas-Sky server {0}", error: message())
  )


}

#env:imports("java.util.LinkedLst", "java.util.HashMap")