###################
# Helper function #
###################

doc"""
    has_ops(ex)

Check if has optional arguments.

```julia
has_ops(parse("@assume x ~ Normal(0, 1; :static=true)"))  # gives true
has_ops(parse("@assume x ~ Normal(0, 1)"))                # gives false
has_ops(parse("@assume x ~ Binomial(; :static=true)"))    # gives true
has_ops(parse("@assume x ~ Binomial()"))                  # gives false
```
"""
function has_ops(right)
  if length(right.args) <= 1               # check if the D() has parameters
    return false                                # Binominal() can have empty
  elseif typeof(right.args[2]) != Expr     # check if has optional arguments
    return false
  elseif right.args[2].head != :parameters # check if parameters valid
    return false
  end
  true
end

function gen_assume_ex(left, right)
  if has_ops(right)
    # If static is set
    if right.args[2].args[1].args[1] == :(:static) && right.args[2].args[1].args[2] == :true
      # Do something
    end
    # If param is set
    if right.args[2].args[1].args[1] == :(:param) && right.args[2].args[1].args[2] == :true
      # Do something
    end
    # Remove the extra argument
    splice!(right.args, 2)
  end

  # The if statement is to deterimnet how to pass the prior.
  # It only supposrts pure symbol and Array(/Dict) now.
  varExpr = ex.args[2]
  if isa(varExpr, Symbol)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Pure Symbol
            Symbol($(string(varExpr)))
          )
        )
      end
    )
  elseif length(varExpr.args) == 2 && isa(varExpr.args[1], Symbol)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2])                   # index value
          )
        )
      end
    )
  elseif length(varExpr.args) == 2 && isa(varExpr.args[1], Expr)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[1].args[2]))),  # index symbol
            $(varExpr.args[1].args[2]),                  # index value
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2])                   # index value
          )
        )
      end
    )
  elseif length(varExpr.args) == 3
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2]),                  # index value
            Symbol($(string(varExpr.args[3]))),  # index symbol
            $(varExpr.args[3])                   # index value
          )
        )
      end
    )
  end
end

#################
# Overload of ~ #
#################

macro ~(left, right)
  if isa(left, Real)                  # value
    esc(println("Call observe"))
  else
    local sym
    if isa(left, Symbol)              # symbol
      sym = left
    elseif isa(left.args[1], Symbol)  # matrix
      sym = left.args[1]
    elseif isa(left.args[1], Expr)    # array of arry
      sym = left.args[1].args[1]
    end
    esc(
      quote
        if isdefined(Symbol($(string(sym))))
          println("Call observe")
        else
          println("Call assume")
          $left = rand($right)
        end
      end
    )
  end
end

##########
# Macros #
##########

doc"""
    assume(ex)

Operation for defining the prior.

Usage:

```julia
@assume x ~ Dist
```

Here `x` is a **symbol** to be used and `Dist` is a valid distribution from the Distributions.jl package. Optional parameters can also be passed (see examples below).

Example:

```julia
@assume x ~ Normal(0, 1)
@assume x ~ Binomial(0, 1)
@assume x ~ Normal(0, 1; :static=true)
@assume x ~ Binomial(0, 1; :param=true)
```
"""
macro assume(ex)
  dprintln(1, "marco assuming...")
  @assert ex.args[1] == Symbol("@~")
  # Check if have extra arguements setting
  if has_ops(ex)
    # If static is set
    if ex.args[3].args[2].args[1].args[1] == :(:static) && ex.args[3].args[2].args[1].args[2] == :true
      # Do something
    end
    # If param is set
    if ex.args[3].args[2].args[1].args[1] == :(:param) && ex.args[3].args[2].args[1].args[2] == :true
      # Do something
    end
    # Remove the extra argument
    splice!(ex.args[3].args, 2)
  end

  # The if statement is to deterimnet how to pass the prior.
  # It only supposrts pure symbol and Array(/Dict) now.
  varExpr = ex.args[2]
  if isa(varExpr, Symbol)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Pure Symbol
            Symbol($(string(varExpr)))
          )
        )
      end
    )
  elseif length(varExpr.args) == 2 && isa(varExpr.args[1], Symbol)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2])                   # index value
          )
        )
      end
    )
  elseif length(varExpr.args) == 2 && isa(varExpr.args[1], Expr)
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[1].args[2]))),  # index symbol
            $(varExpr.args[1].args[2]),                  # index value
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2])                   # index value
          )
        )
      end
    )
  elseif length(varExpr.args) == 3
    esc(
      quote
        $(varExpr) = Turing.assume(
          Turing.sampler,
          $(ex.args[3]),    # dDistribution
          VarInfo(          # Array assignment
            parse($(string(varExpr))),           # indexing expr
            Symbol($(string(varExpr.args[2]))),  # index symbol
            $(varExpr.args[2]),                  # index value
            Symbol($(string(varExpr.args[3]))),  # index symbol
            $(varExpr.args[3])                   # index value
          )
        )
      end
    )
  end

end

doc"""
    observe(ex)

Operation for defining the likelihood.

Usage:

```julia
@observe x ~ Dist
```

Here `x` is a **concrete value** to be used and `Dist` is a valid distribution from the Distributions.jl package. Optional parameters can also be passed (see examples below).

Example:

```julia
@observe x ~ Normal(0, 1)
@observe x ~ Binomial(0, 1)
@observe x ~ Normal(0, 1; :static=true)
@observe x ~ Binomial(0, 1; :param=true)
```
"""
macro observe(ex)
  dprintln(1, "marco observing...")
  @assert ex.args[1] == Symbol("@~")

  global TURING
  # Check if have extra arguements setting
  if has_ops(ex)
    # If static is set
    if ex.args[3].args[2].args[1].args[1] == :(:static) && ex.args[3].args[2].args[1].args[2] == :true
      # Do something
    end
    # If param is set
    if ex.args[3].args[2].args[1].args[1] == :(:param) && ex.args[3].args[2].args[1].args[2] == :true
      # Do something
    end
    # Remove the extra argument
    splice!(ex.args[3].args, 2)
  end

  esc(
    quote
      Turing.observe(
        Turing.sampler,
        $(ex.args[3]),   # Distribution
        $(ex.args[2])    # Data point
      )
    end
  )
end

doc"""
    predict(ex...)

Operation for defining the the variable(s) to return.

Usage:

```julia
@predict x y z
```

Here `x`, `y`, `z` are symbols.
"""
macro predict(ex...)
  dprintln(1, "marco predicting...")
  ex_funcs = Expr(:block)
  for i = 1:length(ex)
    @assert typeof(ex[i]) == Symbol
    sym = string(ex[i])
    push!(
      ex_funcs.args,
      :(ct = current_task();
        Turing.predict(
          Turing.sampler,
          Symbol($sym), get(ct, $(ex[i]))
        )
      )
    )
  end
  esc(ex_funcs)
end

doc"""
    model(name, fbody)

Wrapper for models.

Usage:

```julia
@model f body
```

Example:

```julia
@model gauss begin
  @assume s ~ InverseGamma(2,3)
  @assume m ~ Normal(0,sqrt(s))
  @observe 1.5 ~ Normal(m, sqrt(s))
  @observe 2.0 ~ Normal(m, sqrt(s))
  @predict s m
end
```
"""
macro model(name, fbody)
  dprintln(1, "marco modelling...")
  # Functions defined via model macro have an implicit varinfo array.
  # This varinfo array is useful is task cloning.

  # Turn f into f() if necessary.
  fname = isa(name, Symbol) ? Expr(:call, name) : name
  ex = Expr(:function, fname, fbody)

  # Assign data locally
  local_assign_ex = quote
    for k in keys(data)
      ex = Expr(Symbol("="), k, data[k])
      eval(ex)
    end
  end
  unshift!(fbody.args, local_assign_ex)

  TURING[:modelex] = ex
  return esc(ex)  # esc() makes sure that ex is resovled where @model is called
end
