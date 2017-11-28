
const LambdasSkyClient = require('./lambdas-sky').LambdasSkyClient;

let client = new LambdasSkyClient({server: "http://lambdas-sky.cleverapps.io/lambdas"})

client.call({
  branch: "master",
  owner: "k33g",
  repository: "golo-lambdas",
  path: "hello.golo",
  parameters: {
    name: "👋 Bob Morane"
  }
})
.then(data => console.log(
  data.error ? `😡 (hello) Error: ${data.error}` : `😀 (hello) Result: ${data.computationResult}`
))
.catch(err => console.log("😡 Error: ", err))

client.call({
  branch: "master",
  owner: "k33g",
  repository: "golo-lambdas",
  path: "addition.golo",
  parameters: {
    a: 28, b: 14
  }
})
.then(data => console.log(
  data.error ? `😡 (addition) Error: ${data.error}` : `😀 (addition) Result: ${data.computationResult}`
))
.catch(err => console.log("😡 Error: ", err))

client.call({
  branch: "master",
  owner: "k33g",
  repository: "golo-lambdas",
  path: "neverended.golo",
  parameters: {
    n: 10
  }
})
.then(data => console.log( 
  data.error ? `😡 (neverended) Error: ${data.error}` : `😀 (neverended) Result: ${data.computationResult}`
))
.catch(err => console.log("😡 Error: ", err))

// generate java.util.concurrent.TimeoutException
client.call({
  branch: "master",
  owner: "k33g",
  repository: "golo-lambdas",
  path: "neverended.golo",
  parameters: {
    n: 100
  }
})
.then(data => console.log( 
  data.error ? `😡 (neverended) Error: ${data.error}` : `😀 (neverended) Result: ${data.computationResult}`
))
.catch(err => console.log("😡 Error: ", err))