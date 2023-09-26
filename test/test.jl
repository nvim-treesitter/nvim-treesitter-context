struct Foo{T}
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
    # comment
end

function myfunc(
    x::Vector,
    y::Int,
)
    @assert y > 0
    for i in 1:y
        if i == 0 &&
           i == 0 # Unnecessary condition to go over 2 lines.
            println("zero")
            # comment
            # comment
            # comment
            # comment
            # comment
        elseif i == 1
            println("one")
            # comment
            # comment
            # comment
            # comment
            # comment
        else
            println("other")
            # comment
            # comment
            # comment
            # comment
            # comment
        end
    end
    # comment
    # comment
    # comment
    # comment
    # comment
    foo = y
    while foo > 0 &&
        foo > 0 # Unnecessary condition to go over 2 lines.
        println(foo)
        foo -= 1
        # comment
        # comment
        # comment
        # comment
        # comment
    end
    # comment
    # comment
    # comment
    # comment
    # comment
    try
        sqrt("ten")
        # comment
        # comment
        # comment
        # comment
        # comment
    catch e
        println(e)
        # comment
        # comment
        # comment
        # comment
        # comment
    end
    # comment
    # comment
    # comment
    # comment
    # comment
    return y * x
end
