
# fakegen.rb
# A simple code generator to create some C macros for defining test fake functions


$cpp_output = true
$MAX_ARGS = 10
$DEFAULT_ARG_HISTORY = 50
$MAX_CALL_HISTORY = 50

def output_constants
  putd "#define FFF_MAX_ARGS (#{$MAX_ARGS}u)"
  putd "#ifndef FFF_ARG_HISTORY_LEN"
  putd "    #define FFF_ARG_HISTORY_LEN (#{$DEFAULT_ARG_HISTORY}u)"
  putd "#endif"
  putd "#ifndef FFF_CALL_HISTORY_LEN"
  putd "  #define FFF_CALL_HISTORY_LEN (#{$MAX_CALL_HISTORY}u)"
  putd "#endif"
  putd "#ifndef FFF_RESET_ALL_FAKES_LEN"
  putd "  #define FFF_RESET_ALL_FAKES_LEN (50u)"
  putd "#endif"
end

# ------  Helper macros to use internally ------ #
def output_internal_helper_macros
  putd "/* -- INTERNAL HELPER MACROS -- */"

  define_return_sequence_helper
  define_reset_fake_macro
  define_declare_arg_helper
  define_declare_all_func_common_helper
  define_save_arg_helper
  define_room_for_more_history
  define_save_arg_history_helper
  define_history_dropped_helper
  define_value_function_variables_helper
  define_increment_call_count_helper
  define_return_fake_result_helper
  define_reset_fake_helper
  
  putd "/* -- END INTERNAL HELPER MACROS -- */"
  putd ""
end

def define_return_sequence_helper
  putd "#define SET_RETURN_SEQ(FUNCNAME, ARRAY_POINTER, ARRAY_LEN) \\"
  putd "                        FUNCNAME##_fake.return_val_seq = ARRAY_POINTER; \\"
  putd "                        FUNCNAME##_fake.return_val_seq_len = ARRAY_LEN;"
end

def define_reset_fake_macro
  putd ""
  putd "/* Defining a function to reset a fake function */"
  putd "#define RESET_FAKE(FUNCNAME) { \\"
  putd "    FUNCNAME##_reset(); \\"
  putd "} \\"
  putd ""
end

def define_declare_arg_helper
  putd ""
  putd "#define DECLARE_ARG(type, n) \\"
  putd "    type arg##n##_val; \\"
  putd "    type arg##n##_history[FFF_ARG_HISTORY_LEN];"
end

def define_declare_all_func_common_helper
  putd ""
  putd "#define DECLARE_ALL_FUNC_COMMON \\"
  putd "    unsigned int call_count; \\"
  putd "    unsigned int arg_histories_dropped; \\"
  putd "    unsigned int arg_history_idx; \\"
  putd "    unsigned int arg_history_len; \\"
end

def define_save_arg_helper
  putd ""
  putd "#define SAVE_ARG(FUNCNAME, n) \\"
  putd "    FUNCNAME##_fake.arg##n##_val = arg##n;"
end

def define_room_for_more_history
  putd ""
  putd "#define ROOM_FOR_MORE_HISTORY(FUNCNAME) \\"
  putd "  FUNCNAME##_fake.call_count < FFF_ARG_HISTORY_LEN"
end

def define_save_arg_history_helper
  putd ""
  putd "#define SAVE_ARG_HISTORY(FUNCNAME, ARGN) \\"
  putd "    FUNCNAME##_fake.arg##ARGN##_history[FUNCNAME##_fake.arg_history_len] = arg##ARGN;\\"
end

def define_history_dropped_helper
  putd ""
  putd "#define HISTORY_DROPPED(FUNCNAME) \\"
  putd "    FUNCNAME##_fake.arg_histories_dropped++"
end

def define_value_function_variables_helper
  putd ""
  putd "#define DECLARE_VALUE_FUNCTION_VARIABLES(RETURN_TYPE) \\"
  putd "    RETURN_TYPE return_val; \\" 
  putd "    int return_val_seq_len; \\" 
  putd "    int return_val_seq_idx; \\" 
  putd "    RETURN_TYPE * return_val_seq; \\" 
end

def define_increment_call_count_helper
  putd ""
  putd "#define INCREMENT_CALL_COUNT(FUNCNAME) \\"
  putd "    FUNCNAME##_fake.call_count++"
end

def define_return_fake_result_helper
  putd ""
  putd "#define RETURN_FAKE_RESULT(FUNCNAME) \\"
  putd "    if (FUNCNAME##_fake.return_val_seq_len){ /* then its a sequence */ \\"
  putd "        if(FUNCNAME##_fake.return_val_seq_idx < FUNCNAME##_fake.return_val_seq_len) { \\"
  putd "            return FUNCNAME##_fake.return_val_seq[FUNCNAME##_fake.return_val_seq_idx++]; \\"
  putd "        } \\"
  putd "        return FUNCNAME##_fake.return_val_seq[FUNCNAME##_fake.return_val_seq_len-1]; /* return last element */ \\"
  putd "    } \\"
  putd "    return FUNCNAME##_fake.return_val; \\"
end

def define_extern_c_helper
  putd ""
  putd "#ifdef FFF_NO_EXTERN_C /* production code is C that is compiled with a C++ compiler */"
  putd "    #define EXTERN_C"
  putd "    #define END_EXTERN_C"
  putd "#else"
  putd "    #ifdef __cplusplus"
  putd "        #define EXTERN_C extern \"C\"{"
  putd "        #define END_EXTERN_C } "
  putd "    #else  /* ansi c */"
  putd "        #define EXTERN_C "
  putd "        #define END_EXTERN_C "
  putd "    #endif"
  putd "#endif"
end

def declare_global_functions_and_structs
  putd <<-GLOBAL_FUNCS_AND_STRUCTS

/* Global functions and structs */
EXTERN_C
typedef void (*reset_fake_function_t)(void);

void fff_register_fake(reset_fake_function_t reset_fake);
void fff_reset(void);
void fff_memset(void * ptr, int value, int num);

typedef struct {
    void * call_history[FFF_CALL_HISTORY_LEN];
    unsigned int call_history_idx;
    reset_fake_function_t reset_fake[FFF_RESET_ALL_FAKES_LEN];
    unsigned int reset_fakes_count;
    int call_history_overflow;
    int registration_overflow;
} fff_globals_t;

#define FFF_OVERFLOW \
	(fff.call_history_overflow || fff.registration_overflow)

#define FFF_RESET_HISTORY() fff.call_history_idx = 0;

#define FFF_RESET fff_reset()
END_EXTERN_C

  GLOBAL_FUNCS_AND_STRUCTS

end

def define_reset_fake_helper
  putd ""
  putd "#define DEFINE_RESET_FUNCTION(FUNCNAME) \\"
  putd "    void FUNCNAME##_reset(){ \\"
  putd "        fff_memset(&FUNCNAME##_fake, 0, (int)sizeof(FUNCNAME##_fake)); \\"
  putd "    }"
end
# ------  End Helper macros ------ #

#fakegen helpers to print at levels of indentation
$current_depth = 0
def putd(str)
  $current_depth.times {|not_used| print " "}
  puts str
end

def pushd
  $current_depth = $current_depth + 4
end

def popd
  $current_depth = $current_depth - 4
end

def output_macro(arg_count, is_value_function)

  fake_macro_name = is_value_function ? "FAKE_VALUE_FUNC#{arg_count}" : "FAKE_VOID_FUNC#{arg_count}";
  declare_macro_name = "DECLARE_#{fake_macro_name}"
  define_macro_name = "DEFINE_#{fake_macro_name}"

  return_type = is_value_function ? "RETURN_TYPE" : ""

  putd ""
  output_macro_header(declare_macro_name, arg_count, return_type)
  pushd
    extern_c {  # define argument capture variables
      output_variables(arg_count, is_value_function)
    }
  popd
  
  putd ""
  output_macro_header(define_macro_name, arg_count, return_type)
  pushd
    extern_c {
      putd "FUNCNAME##_Fake FUNCNAME##_fake;\\"
      putd function_signature(arg_count, is_value_function) + "{ \\"
      pushd
        output_function_body(arg_count, is_value_function)
      popd
      putd "} \\"
      putd "DEFINE_RESET_FUNCTION(FUNCNAME) \\"
    }
  popd
  
  putd ""
  
  output_macro_header(fake_macro_name, arg_count, return_type)
  pushd
    putd macro_signature_for(declare_macro_name, arg_count, return_type)
    putd macro_signature_for(define_macro_name, arg_count, return_type)
    putd ""
  popd
end

def output_macro_header(macro_name, arg_count, return_type)
  output_macro_name(macro_name, arg_count, return_type)
end

# #define #macro_name(RETURN_TYPE, FUNCNAME, ARG0,...)
def output_macro_name(macro_name, arg_count, return_type)
  putd "#define " + macro_signature_for(macro_name, arg_count, return_type)
end

# #macro_name(RETURN_TYPE, FUNCNAME, ARG0,...)
def macro_signature_for(macro_name, arg_count, return_type)
  parameter_list = "#{macro_name}("
  if return_type != ""
    parameter_list += return_type
    parameter_list += ", "
  end
  parameter_list += "FUNCNAME"

  arg_count.times { |i| parameter_list += ", ARG#{i}_TYPE" }

  parameter_list +=  ") \\"
  
  parameter_list
end

def output_argument_capture_variables(argN)
  putd "    DECLARE_ARG(ARG#{argN}_TYPE, #{argN}) \\"
end

def output_variables(arg_count, is_value_function)
  in_struct{
    arg_count.times { |argN| 
      putd "DECLARE_ARG(ARG#{argN}_TYPE, #{argN}) \\"
    }
    putd "DECLARE_ALL_FUNC_COMMON \\"
    putd "DECLARE_VALUE_FUNCTION_VARIABLES(RETURN_TYPE) \\" unless not is_value_function
    output_custom_function_signature(arg_count, is_value_function)
  }
  putd "extern FUNCNAME##_Fake FUNCNAME##_fake;\\"
  putd "void FUNCNAME##_reset(); \\"
end

#example: ARG0_TYPE arg0, ARG1_TYPE arg1
def arg_val_list(args_count)
  arguments = []
  args_count.times { |i| arguments << "ARG#{i}_TYPE arg#{i}" }
  arguments.join(", ")
end

#example: arg0, arg1
def arg_list(args_count)
  arguments = []
  args_count.times { |i| arguments << "arg#{i}" }
  arguments.join(", ")
end

# RETURN_TYPE (*custom_fake)(ARG0_TYPE arg0);\
# void (*custom_fake)(ARG0_TYPE arg0, ARG1_TYPE arg1, ARG2_TYPE arg2);\
def output_custom_function_signature(arg_count, is_value_function)
  return_type = is_value_function ? "RETURN_TYPE" : "void"
  signature = "(*custom_fake)(#{arg_val_list(arg_count)}); \\"
  putd return_type + signature
end

# example: RETURN_TYPE FUNCNAME(ARG0_TYPE arg0, ARG1_TYPE arg1)
def function_signature(arg_count, is_value_function)
  return_type = is_value_function ? "RETURN_TYPE" : "void"
  "#{return_type} FUNCNAME(#{arg_val_list(arg_count)})"
end

def output_function_body(arg_count, is_value_function)
  putd "FFF_REGISTER_FAKE(FUNCNAME);\\"
  arg_count.times { |i| putd "SAVE_ARG(FUNCNAME, #{i}); \\" }
  putd "if(ROOM_FOR_MORE_HISTORY(FUNCNAME)){\\"
  arg_count.times { |i| putd "    SAVE_ARG_HISTORY(FUNCNAME, #{i}); \\" }
  putd "    FUNCNAME##_fake.arg_history_len++;\\"
  putd "}\\"
  putd "else{\\"
  putd "    HISTORY_DROPPED(FUNCNAME);\\"
  putd "}\\"
  putd "INCREMENT_CALL_COUNT(FUNCNAME); \\"
  putd "REGISTER_CALL((void*)FUNCNAME); \\"
  
  return_type = is_value_function ? "return" : ""
  putd "if (FUNCNAME##_fake.custom_fake) #{return_type} FUNCNAME##_fake.custom_fake(#{arg_list(arg_count)}); \\"
  
  putd "RETURN_FAKE_RESULT(FUNCNAME)  \\" if is_value_function
end

def define_fff_globals
  putd <<-DEFINE_GLOBALS_MACRO

/* -- GLOBAL HELPERS -- */

EXTERN_C
  extern fff_globals_t fff;
END_EXTERN_C

#define FFF_DEFINE_GLOBALS \\
  EXTERN_C \\
    fff_globals_t fff; \\
\\
    void fff_memset(void * ptr, int value, int num )\\
    {\\
      int i;\\
      char * p = (char*)ptr;\\
      for (i = 0; i < num; i++, p++)\\
        *p = (char)value;\\
    }\\
\\
    void fff_register_fake(reset_fake_function_t reset_fake)\\
    {\\
      if (fff.reset_fakes_count >= FFF_RESET_ALL_FAKES_LEN)\\
        fff.registration_overflow = 1;\\
      else\\
      {\\
            unsigned int i;\\
            for (i = 0; i < fff.reset_fakes_count; i++)\\
            {\\
              if (fff.reset_fake[i] == reset_fake)\\
                    return;\\
            }\\
            fff.reset_fake[fff.reset_fakes_count++] = reset_fake;\\
      }\\
    }\\
\\
    void fff_reset(void)\\
    {\\
      unsigned int i;\\
      for (i = 0; i < fff.reset_fakes_count; i++)\\
        fff.reset_fake[i]();\\
      fff_memset(&fff, 0, sizeof(fff));\\
    }\\
\\
  END_EXTERN_C
  
#define DEFINE_FFF_GLOBALS FFF_DEFINE_GLOBALS

#define FFF_REGISTER_FAKE(FUNCNAME) fff_register_fake(FUNCNAME##_reset);

#define REGISTER_CALL(function) \\
   if(fff.call_history_idx < FFF_CALL_HISTORY_LEN) \\
       fff.call_history[fff.call_history_idx++] = (void *)function;\
     else\
       fff.call_history_overflow = 1;

/* -- END GLOBAL HELPERS -- */
  DEFINE_GLOBALS_MACRO
end

def extern_c
  putd "EXTERN_C \\"
  pushd 
    yield
  popd
  putd "END_EXTERN_C \\"
end

def in_struct
  putd "typedef struct FUNCNAME##_Fake { \\"
  pushd
  yield
  popd
  putd "} FUNCNAME##_Fake;\\"
end

def include_guard
  putd "#ifndef FAKE_FUNCTIONS"
  putd "#define FAKE_FUNCTIONS"
  putd ""

  yield

  putd ""
  putd "#endif"
end

def output_macro_counting_shortcuts
  putd <<-MACRO_COUNTING

#define PP_NARG_MINUS2(...) \
    PP_NARG_MINUS2_(__VA_ARGS__, PP_RSEQ_N_MINUS2())

#define PP_NARG_MINUS2_(...) \
    PP_ARG_MINUS2_N(__VA_ARGS__)

#define PP_ARG_MINUS2_N(returnVal, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, N, ...)   N

#define PP_RSEQ_N_MINUS2() \
    9,8,7,6,5,4,3,2,1,0


#define FAKE_VALUE_FUNC(...) \
    FUNC_VALUE_(PP_NARG_MINUS2(__VA_ARGS__), __VA_ARGS__)

#define FUNC_VALUE_(N,...) \
    FUNC_VALUE_N(N,__VA_ARGS__)

#define FUNC_VALUE_N(N,...) \
    FAKE_VALUE_FUNC ## N(__VA_ARGS__)



#define PP_NARG_MINUS1(...) \
    PP_NARG_MINUS1_(__VA_ARGS__, PP_RSEQ_N_MINUS1())

#define PP_NARG_MINUS1_(...) \
    PP_ARG_MINUS1_N(__VA_ARGS__)

#define PP_ARG_MINUS1_N(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, N, ...)   N

#define PP_RSEQ_N_MINUS1() \
    9,8,7,6,5,4,3,2,1,0

#define FAKE_VOID_FUNC(...) \
    FUNC_VOID_(PP_NARG_MINUS1(__VA_ARGS__), __VA_ARGS__)

#define FUNC_VOID_(N,...) \
    FUNC_VOID_N(N,__VA_ARGS__)

#define FUNC_VOID_N(N,...) \
    FAKE_VOID_FUNC ## N(__VA_ARGS__)

  MACRO_COUNTING
end

def output_declare_define_macros
  putd <<-DEFINE_DECLARE_MACROS
#define DECLARE_FAKE_VALUE_FUNC(...)  DECLARE_FUNC_VALUE_(PP_NARG_MINUS2(__VA_ARGS__), __VA_ARGS__)
#define DECLARE_FUNC_VALUE_(N,...)    DECLARE_FUNC_VALUE_N(N,__VA_ARGS__)
#define DECLARE_FUNC_VALUE_N(N,...)   DECLARE_FAKE_VALUE_FUNC ## N(__VA_ARGS__)

#define DEFINE_FAKE_VALUE_FUNC(...)   DEFINE_FUNC_VALUE_(PP_NARG_MINUS2(__VA_ARGS__), __VA_ARGS__)
#define DEFINE_FUNC_VALUE_(N,...)     DEFINE_FUNC_VALUE_N(N,__VA_ARGS__)
#define DEFINE_FUNC_VALUE_N(N,...)    DEFINE_FAKE_VALUE_FUNC ## N(__VA_ARGS__)

#define DECLARE_FAKE_VOID_FUNC(...)   DECLARE_FUNC_VOID_(PP_NARG_MINUS1(__VA_ARGS__), __VA_ARGS__)
#define DECLARE_FUNC_VOID_(N,...)     DECLARE_FUNC_VOID_N(N,__VA_ARGS__)
#define DECLARE_FUNC_VOID_N(N,...)    DECLARE_FAKE_VOID_FUNC ## N(__VA_ARGS__)

#define DEFINE_FAKE_VOID_FUNC(...)    DEFINE_FUNC_VOID_(PP_NARG_MINUS1(__VA_ARGS__), __VA_ARGS__)
#define DEFINE_FUNC_VOID_(N,...)      DEFINE_FUNC_VOID_N(N,__VA_ARGS__)
#define DEFINE_FUNC_VOID_N(N,...)     DEFINE_FAKE_VOID_FUNC ## N(__VA_ARGS__)

  DEFINE_DECLARE_MACROS
end

def output_generate_fakes_macros
putd <<-GENERATE_FAKES_MACROS

#ifdef FFF_GENERATE_FAKE_DEFINES
    #undef FAKE_VALUE_FUNCTION
    #undef FAKE_VOID_FUNCTION
    #define FAKE_VALUE_FUNCTION DEFINE_FAKE_VALUE_FUNC
    #define FAKE_VOID_FUNCTION DEFINE_FAKE_VOID_FUNC
#else
    #define FAKE_VALUE_FUNCTION DECLARE_FAKE_VALUE_FUNC
    #define FAKE_VOID_FUNCTION DECLARE_FAKE_VOID_FUNC
#endif
  
  GENERATE_FAKES_MACROS
end

def output_c_and_cpp

  include_guard {
    output_constants
    define_extern_c_helper
    declare_global_functions_and_structs
    output_internal_helper_macros
    define_fff_globals
    yield
    output_macro_counting_shortcuts
    output_declare_define_macros
    }
  output_generate_fakes_macros
end

# lets generate!!
output_c_and_cpp{
  $MAX_ARGS.times {|arg_count| output_macro(arg_count, false)}
  $MAX_ARGS.times {|arg_count| output_macro(arg_count, true)}
}
