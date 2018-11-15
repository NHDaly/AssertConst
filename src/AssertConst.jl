module AssertConst

export @assertconst

using InteractiveUtils

macro assertconst(f)
    if isa(f, Expr) && (f.head === :function || Base.is_short_function_def(f))
        signature = f.args[1]
        (fname, fargs) = signature.args[1], signature.args[2:end]
        body = f.args[2]
        lno = body.args[1]
        return Expr(:escape,
                    Expr(f.head, signature,
                         Expr(:block,
                              lno,
                              Expr(:call, assert_is_constexpr, fname, fargs),
                              body)))
    else
        error("invalid syntax; @assertconst must be used with a function definition")
    end
end

Base.@pure function assert_is_constexpr(f, args)
    isconstexpr, failures = is_constexpr(f, args)
    if !isconstexpr
        throw(AssertionError("""Function marked @assertconst has non-const return values:
                              $(join(failures, "\n"))"""))
    end
end
Base.@pure function is_constexpr(f, args)
    (CI,r) = InteractiveUtils.@code_typed optimize=false f(args...)
    failures = []
    for e in CI.code
        if e isa Core.Compiler.Const && e.val isa Expr && e.val.head == :return
            return_statement = e.val
        elseif e isa Expr && e.head == :return
            return_statement = e
        else
            continue
        end
        return_value = CI.ssavaluetypes[return_statement.args[1].id]
        if !(return_value isa Core.Compiler.Const)
            push!(failures, (return_statement => return_value))
        end
    end
    return isempty(failures), failures
end


end
