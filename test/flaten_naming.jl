using Distributions
using ForwardDiff: Dual
using Turing
using Turing: Var, parse_indexing
using Base.Test

# Symbol
v_sym = Var(:x)
@test v_sym.uid == :x

# Array
i = 1
v_arr = Var(:x, Symbol(eval(parse_indexing(:(x[i])))))
@test v_arr.uid == Symbol("x[1]")

# Matrix
i, j = 1, 2
v_mat = Var(:x, Symbol(eval(parse_indexing(:(x[i,j])))))
@test v_mat.uid == Symbol("x[1,2]")

@model mat_name_test begin
  p = Array{Dual}((2, 2))
  for i in 1:2, j in 1:2
    p[i,j] ~ Normal(0, 1)
  end
  p
end
chain = sample(mat_name_test, HMC(1000, 0.75, 2))
@test_approx_eq_eps mean(mean(chain[:p])) 0 0.25

# Multi array
i, j = 1, 2
v_arrarr = Var(:x, Symbol(eval(parse_indexing(:(x[i][j])))))
@test v_arrarr.uid == Symbol("x[1][2]")

@model marr_name_test begin
  p = Array{Array{Dual}}(2)
  p[1] = Array{Dual}(2)
  p[2] = Array{Dual}(2)
  for i in 1:2, j in 1:2
    p[i][j] ~ Normal(0, 1)
  end
  p
end
chain = sample(marr_name_test, HMC(1000, 0.75, 2))
@test_approx_eq_eps mean(mean(mean(chain[:p]))) 0 0.25
