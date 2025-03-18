# {{TEST}}
defmodule Foo do # {{CONTEXT}}
  @moduledoc """ {{CONTEXT}}
  Some really long




  documentation. {{CURSOR}}
  """ # {{POPCONTEXT}}

  @some_const ~w[ # {{CONTEXT}}
    hi
    i'm
    a
    big
    list
    sigil # {{CURSOR}}
  ] # {{POPCONTEXT}}



  def run(%{ # {{CONTEXT}}
    multi: multi,
    line: line,
    function_clause: function_clause
  }) do


    # BUG: max context lines reached
    case line do


    {:ok, foos}->
        Enum.map(foos, fn
          {f, f2} ->



            String.downcase(f2)

            f ->





          String.upcase(f)

        end)


      _ ->
        with some_num <- Enum.random(1..100),
             another_num <- Enum.random(1..100) do
          # TODO: all of it



          end




        :ok
    end
  end

  def stop(params) do
    %{
      foo: %{
        "alice" => "alice",
        "bob" => "bob",
        "carol" => "carol",
        "dave" => "dave",



        "bar" => [
          :bing,
          %{
            "very deeply nested" => %{



              "jk, even deeper" => %{



                "one more" => %{



                }
              }
            }
          }



          :bong,


          :bang
        ]
      }
    }

  end
end
