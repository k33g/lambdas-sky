const LambdasSkyClient = require('./lambdas-sky').LambdasSkyClient;

let client = new LambdasSkyClient({server: "http://localhost:9090/lambdas"})

client.call({
  branch: "sandbox",
  owner: "k33g",
  repository: "pony",
  path: "blue/hello.golo",
  parameters: {
    name: "👋 Bob Morane"
  }
})
.then(data => console.log( data.error ? `😡 Error: ${data.error}` : `😀 Result: ${data.computationResult}`))
.catch(err => console.log("😡 Error: ", err))

client.call({
  branch: "master",
  owner: "k33g",
  repository: "pony",
  path: "addition.golo",
  parameters: {
    a: 28, b: 14
  }
})
.then(data => console.log( data.error ? `😡 Error: ${data.error}` : `😀 Result: ${data.computationResult}`))
.catch(err => console.log("😡 Error: ", err))