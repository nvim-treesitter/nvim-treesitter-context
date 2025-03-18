-- {{TEST}}
function arg1 arg2 = -- {{CONTEXT}}














    -- {{CURSOR}}
    case (arg1, arg2) of












        -- {{CURSOR}}

        (Just _, Just _) -> do -- {{CONTEXT}}












            -- {{CURSOR}}


            undefined -- {{POPCONTEXT}}
















        -- {{CURSOR}}
        _ -> undefined
