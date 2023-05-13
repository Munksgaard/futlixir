#include <erl_nif.h>
#include "lib_map.c"

struct futhark_context;

ErlNifResourceType* CONFIG_TYPE;
ErlNifResourceType* CONTEXT_TYPE;
ERL_NIF_TERM atom_ok;


static int open_config(ErlNifEnv* env)
{
    const char* mod = "resources";
    const char* name = "Config";
    int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

    CONFIG_TYPE = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
    if(CONFIG_TYPE == NULL) return -1;
    return 0;
}

static int open_context(ErlNifEnv* env)
{
    const char* mod = "resources";
    const char* name = "Context";
    int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

    CONTEXT_TYPE = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
    if(CONFIG_TYPE == NULL) return -1;
    return 0;
}


static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
    if(open_config(env) == -1) return -1;
    if(open_context(env) == -1) return -1;

    atom_ok = enif_make_atom(env, "ok");

    return 0;
}

static ERL_NIF_TERM futhark_context_config_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context_config **res;

  ERL_NIF_TERM ret;

  if(argc != 0) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(CONFIG_TYPE, sizeof(struct futhark_context_config *));
  if(res == NULL) return enif_make_badarg(env);

  struct futhark_context_config* tmp = futhark_context_config_new();

  *res = tmp;

  ret = enif_make_resource(env, res);
  enif_release_resource(res);

  return enif_make_tuple2(env, atom_ok, ret);
}

static ERL_NIF_TERM futhark_context_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context_config **cfg;
  struct futhark_context *res;

  ERL_NIF_TERM ret;

  if(argc != 1) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(CONTEXT_TYPE, sizeof(struct futhark_context *));
  if(res == NULL) return enif_make_badarg(env);

  ret = enif_make_resource(env, res);
  enif_release_resource(res);

  struct futhark_context* tmp = futhark_context_new(*cfg);

  res = tmp;

  return enif_make_tuple2(env, atom_ok, ret);
}

static ErlNifFunc nif_funcs[] = {
  {"futhark_context_config_new", 0, futhark_context_config_new_nif},
  {"futhark_context_new", 1, futhark_context_new_nif}
};

ERL_NIF_INIT(Elixir.Calc, nif_funcs, &load, NULL, NULL, NULL)
