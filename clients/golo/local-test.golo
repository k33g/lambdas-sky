module demo

import lambdas.sky

----
golo golo --files imports/*.golo local-test.golo 
----
function main = |args| {
  let cli = lambdas.sky.client("http://localhost:9090/lambdas")
  let res = cli: call(DynamicObject()
    : branch("master")
    : owner("k33g")
    : repository("pony")
    : path("addition.golo")
    : parameters(DynamicObject() :a(28) :b(14))
  )
  println(res: computationResult())
}
