-- {{TEST}}

local function foo() -- {{CONTEXT}}

  local function bar() -- {{CONTEXT}}



   -- {{CURSOR}}

  end

end

-- {{TEST}}

local t = { f = function(a, -- {{CONTEXT}}
  b) -- {{CONTEXT}}



  -- {{CURSOR}}

end }
