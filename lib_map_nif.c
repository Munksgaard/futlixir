#include <erl_nif.h>
#include "lib_map.h"

static ERL_NIF_TERM futhark_context_config_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context_config *cfg = futhark_context_config_new();


  ERL_NIF_TERM term = enif_make_resource(env, cfg);
  enif_release_resource(cfg);

  return term;
}
