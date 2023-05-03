(annotation_directive
   ".end annotation" @context.end
) @context

(array_data_directive
   ".end array-data" @context.end
) @context

(field_definition
   ".end field" @context.end
) @context

(method_definition
   ".end method" @context.end
) @context

(packed_switch_directive
   ".end packed-switch" @context.end
) @context

(param_directive
   ".end param"? @context.end
) @context

(parameter_directive
   ".end parameter"? @context.end
) @context

(sparse_switch_directive
   ".end sparse-switch" @context.end
) @context

(subannotation_directive
   ".end subannotation" @context.end
) @context
