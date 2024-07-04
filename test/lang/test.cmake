
foreach(subdir
        os
        api
        api/private
        msgpack_rpc
        tui
        event
        eval
        lua
        viml
        viml/parser
       )

  if(WIN32)














    add_custom_command(



      OUTPUT ${GEN_EVAL_FILES}




      COMMAND ${PROJECT_SOURCE_DIR}/scripts/gen_eval_files.lua



      DEPENDS
        ${API_METADATA}
        ${PROJECT_SOURCE_DIR}/scripts/gen_eval_files.lua
        ${PROJECT_SOURCE_DIR}/src/nvim/eval.lua
        ${PROJECT_SOURCE_DIR}/src/nvim/options.lua
        ${PROJECT_SOURCE_DIR}/runtime/doc/api.mpack
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    )





  elseif(APPLE)



























  endif()






endforeach()
