module demo

import lambdas.sky

----
golo golo --files imports/*.golo remote-test.golo 
----
function main = |args| {
  let cli = lambdas.sky.client("http://lambdas-sky.cleverapps.io/lambdas")
  let res = cli: call(DynamicObject()
    : branch("master")
    : owner("k33g")
    : repository("golo-lambdas")
    : path("addition.golo")
    : parameters(DynamicObject() :a(28) :b(14))
  )
  println(res: computationResult())
}
