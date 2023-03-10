defmodule Foo do
  @moduledoc """
  Some really long




  documentation.
  """

  @some_const ~w[
    hi
    i'm
    a
    big
    list
    sigil
  ]



  def run(%{
    multi: multi,
    line: line,
    function_clause: function_clause
  }) do



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
