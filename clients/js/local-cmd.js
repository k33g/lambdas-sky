
const LambdasSkyClient = require('./lambdas-sky').LambdasSkyClient;

let client = new LambdasSkyClient({server: "http://localhost:9090/lambdas"})

client.call({
  branch: "master",
  owner: "k33g",
  repository: "pony",
  path: "exec.golo",
  parameters: {
    name: "👋 Bob Morane"
  }
})
.then(data => console.log(
  data.error ? `😡 Error: ${data.error}` : `😀 Result: ${data.computationResult}`)
)
.catch(err => console.log("😡 Error: ", err))
