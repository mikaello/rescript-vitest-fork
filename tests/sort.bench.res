open Vitest.Benchmark

describe("sort", () => {
  bench("normal", _ => {
    let x = [1, 5, 4, 2, 3]
    x
    ->Array.toSorted((a, b) => Int.toFloat(a - b))
    ->ignore
  })

  bench("reverse", _ => {
    let x = [1, 5, 4, 2, 3]
    x
    ->Array.toReversed
    ->Array.toSorted((a, b) => Int.toFloat(a - b))
    ->ignore
  })

  benchAsync("async", ~time=10, ~iterations=1, async _ => {
    await Promise.resolve()
  })

  Todo.bench("todo")
})
