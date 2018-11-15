using Test
include("../src/AssertConst.jl")


@assertconst h(x) = x > 0 ? x : -x

# h()
@test_throws AssertionError h(5)

Base.@pure g() = sin(3)
@assertconst f() = g()

# f()
@test f() == g()
