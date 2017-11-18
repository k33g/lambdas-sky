const fetch = require('node-fetch');

class LambdasSkyClient {
  constructor({server}) {
    this.server = server
  }
  call({branch, owner, repository, path, parameters}) {
    return fetch(this.server, {
      method: "POST",
      body: JSON.stringify({
        branch: branch,
        owner: owner,
        repository: repository,
        path: path,
        parameters: parameters
      })
    })
    .then(res => res.json())
  }
}

module.exports = {
  LambdasSkyClient: LambdasSkyClient
}