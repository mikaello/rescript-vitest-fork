// TODO: import rescript-tinybench

type suiteOptions = {
  skip?: bool,
  only?: bool,
  todo?: bool,
}

type benchOptions = {
  time?: int,
  iterations?: int,
  throws?: bool,
  warmupTime?: int,
  warmupIterations?: int,
}

type benchmarkContext
type benchmarkRegistration

type suiteDef = (string, suiteOptions, unit => unit) => unit
type testDef = (string, suiteOptions, benchmarkContext => promise<unit>) => unit

@send
external register: (benchmarkContext, string, unit => unit) => benchmarkRegistration = "bench"

@send
external registerAsync: (benchmarkContext, string, unit => promise<unit>) => benchmarkRegistration =
  "bench"

@send external run: (benchmarkRegistration, benchOptions) => promise<unit> = "run"

module type Bindings = {
  let describe: suiteDef
  let test: testDef
}

module type Runner = {
  let describe: (string, ~skip: bool=?, ~only: bool=?, ~todo: bool=?, unit => unit) => unit
  let bench: (
    string,
    ~time: int=?,
    ~iterations: int=?,
    ~throws: bool=?,
    ~warmupTime: int=?,
    ~warmupIterations: int=?,
    unit => unit,
  ) => unit
  let benchAsync: (
    string,
    ~time: int=?,
    ~iterations: int=?,
    ~throws: bool=?,
    ~warmupTime: int=?,
    ~warmupIterations: int=?,
    unit => promise<unit>,
  ) => unit
}

module MakeRunner = (Bindings: Bindings) => {
  @inline
  let describe = (name, ~skip=?, ~only=?, ~todo=?, callback) =>
    Bindings.describe(
      name,
      {
        ?skip,
        ?only,
        ?todo,
      },
      callback,
    )

  @inline
  let bench = (
    name,
    ~time=?,
    ~iterations=?,
    ~throws=?,
    ~warmupTime=?,
    ~warmupIterations=?,
    callback,
  ) =>
    Bindings.test(name, {}, async context => {
      let registration = context->register(name, callback)
      await registration->run({?time, ?iterations, ?throws, ?warmupTime, ?warmupIterations})
    })

  @inline
  let benchAsync = (
    name,
    ~time=?,
    ~iterations=?,
    ~throws=?,
    ~warmupTime=?,
    ~warmupIterations=?,
    callback,
  ) =>
    Bindings.test(name, {}, async context => {
      let registration = context->registerAsync(name, callback)
      await registration->run({?time, ?iterations, ?throws, ?warmupTime, ?warmupIterations})
    })
}

include MakeRunner({
  @module("vitest") @val
  external describe: suiteDef = "describe"

  @module("vitest") @val
  external test: testDef = "test"
})

module Only = {
  type only_describe
  type only_test

  %%private(
    @module("vitest") @val
    external only_describe: only_describe = "describe"

    @module("vitest") @val
    external only_test: only_test = "test"
  )

  @get
  external describe: only_describe => suiteDef = "only"

  @get
  external test: only_test => testDef = "only"

  include MakeRunner({
    let describe = only_describe->describe
    let test = only_test->test
  })
}

module Skip = {
  type skip_describe
  type skip_test

  %%private(
    @module("vitest") @val
    external skip_describe: skip_describe = "describe"

    @module("vitest") @val
    external skip_test: skip_test = "test"
  )

  @get
  external describe: skip_describe => suiteDef = "skip"

  @get
  external test: skip_test => testDef = "skip"

  include MakeRunner({
    let describe = skip_describe->describe
    let test = skip_test->test
  })
}

module Todo = {
  type todo_describe
  type todo_test

  %%private(
    @module("vitest") @val
    external todo_describe: todo_describe = "describe"

    @module("vitest") @val
    external todo_test: todo_test = "test"
  )

  @send
  external describe: (todo_describe, string) => unit = "todo"
  @inline
  let describe = name => todo_describe->describe(name)

  @send
  external bench: (todo_test, string) => unit = "todo"
  @inline
  let bench = name => todo_test->bench(name)

  @send
  external benchAsync: (todo_test, string) => unit = "todo"
  @inline
  let benchAsync = name => todo_test->benchAsync(name)
}
