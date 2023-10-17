([
  (LoopTypeExpr)
  (IfTypeExpr)
  (TestDecl)
  (SwitchExpr)
] @context)

(Decl
  (FnProto  (_))
  (Block (_) @context.end)
) @context

(VarDecl
  (ErrorUnionExpr (_)  @context.end)
) @context

(IfStatement
  (BlockExpr (_) @context.end)
) @context

(LoopStatement
  (_ (BlockExpr (_) @context.end))
) @context

(LoopExpr
  (_ (Block (_) @context.end))
) @context

(SwitchProng
  (AssignExpr) @context.end
) @context

