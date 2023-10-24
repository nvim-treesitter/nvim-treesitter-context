(TestDecl) @context.function

(LoopTypeExpr) @context.loop

([
  (IfTypeExpr)
  (SwitchExpr)
] @context.conditional)

(Decl
  (FnProto  (_))
  (Block (_) @context.end)
) @context.function

(VarDecl
  (ErrorUnionExpr
    (SuffixExpr
      (ContainerDecl (ContainerDeclType) (_) @context.end)
    )
  )
) @context.type

(VarDecl
  (ErrorUnionExpr
    (SuffixExpr
      (ErrorSetDecl (_) @context.end)
    )
  )
) @context.type

(IfStatement
  (BlockExpr (_) @context.end)
) @context.conditional

(SwitchProng
  (AssignExpr) @context.end
) @context.conditional

(LoopStatement
  (_ (BlockExpr (_) @context.end))
) @context.loop

(LoopExpr
  (_ (Block (_) @context.end))
) @context.loop

