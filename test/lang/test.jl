# {{TEST}}
struct Foo{T} # {{CONTEXT}}
    bar::T # T can be any type
    baz::Int
    # comment
    # comment
    # comment
    # comment
    # comment
    # comment
    # comment
    # comment
    # comment
    # {{CURSOR}}
end
# {{TEST}}
function myfunc( # {{CONTEXT}}
    x::Vector, # {{CONTEXT}}
    y::Int, # {{CONTEXT}}
) # {{CONTEXT}}
    @assert y > 0
    for i in 1:y # {{CONTEXT}}
        if i == 0 && # {{CONTEXT}}
            i == 0 # {{CONTEXT}}
            println("zero")
            # comment
            # comment
            # comment
            # comment
            # {{CURSOR}}
        elseif i == 1
            println("one")
            # comment
            # comment
            # comment
            # comment
            # {{CURSOR}}
        else
            println("other")
            # comment
            # comment
            # comment
            # comment
            # {{CURSOR}}
        end # {{POPCONTEXT}}
        # {{POPCONTEXT}}
    end # {{POPCONTEXT}}
    # comment
    # comment
    # comment
    # comment
    # {{CURSOR}}
    foo = y
    while foo > 0 && # {{CONTEXT}}
        foo > 0 # {{CONTEXT}}
        println(foo)
        foo -= 1
        # comment
        # comment
        # comment
        # comment
        # {{CURSOR}}
    end # {{POPCONTEXT}}
    # {{POPCONTEXT}}
    # comment
    # comment
    # comment
    # {{CURSOR}}
    try # {{CONTEXT}}
        sqrt("ten")
        # comment
        # comment
        # comment
        # comment
        # {{CURSOR}}
    catch e
        println(e)
        # comment
        # comment
        # comment
        # comment
        # {{CURSOR}}
    end # {{POPCONTEXT}}
    # comment
    # comment
    # comment
    # comment
    # {{CURSOR}}
    return y * x
end
