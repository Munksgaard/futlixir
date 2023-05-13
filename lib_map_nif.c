#include <erl_nif.h>
#include "lib_map.c"

struct futhark_context;

ErlNifResourceType* CONFIG_TYPE;
ErlNifResourceType* CONTEXT_TYPE;
ErlNifResourceType* U8_1D;
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

static int open_u8_1d(ErlNifEnv* env)
{
    const char* mod = "resources";
    const char* name = "u8_1d";
    int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

    U8_1D = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
    if(U8_1D == NULL) return -1;
    return 0;
}


static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
    if(open_config(env) == -1) return -1;
    if(open_context(env) == -1) return -1;
    if(open_u8_1d(env) == -1) return -1;

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
  struct futhark_context **res;

  ERL_NIF_TERM ret;

  if(argc != 1) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(CONTEXT_TYPE, sizeof(struct futhark_context *));
  if(res == NULL) return enif_make_badarg(env);

  struct futhark_context* tmp = futhark_context_new(*cfg);

  *res = tmp;

  ret = enif_make_resource(env, res);
  enif_release_resource(res);

  return enif_make_tuple2(env, atom_ok, ret);
}

static ERL_NIF_TERM futhark_new_u8_1d_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context **ctx;
  ErlNifBinary bin;

  struct futhark_u8_1d **res;
  ERL_NIF_TERM ret;

  if(argc != 2) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
    return enif_make_badarg(env);
  }

  if (!enif_inspect_binary(env, argv[1], &bin)) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(U8_1D, sizeof(struct futhark_u8_1d *));
  if(res == NULL) return enif_make_badarg(env);

  struct futhark_u8_1d* tmp = futhark_new_u8_1d(*ctx, (const uint8_t *)bin.data, bin.size / sizeof(uint8_t));
  const int64_t *shape = futhark_shape_u8_1d(*ctx, tmp);

  *res = tmp;

  ret = enif_make_resource(env, res);
  enif_release_resource(res);

  return enif_make_tuple2(env, atom_ok, ret);
}


static ERL_NIF_TERM futhark_context_sync_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context **ctx;

  if(argc != 1) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
    return enif_make_badarg(env);
  }

  futhark_context_sync(*ctx);

  return atom_ok;
}

static ERL_NIF_TERM futhark_entry_add_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context **ctx;
  struct futhark_u8_1d **xs;
  struct futhark_u8_1d **ys;

  struct futhark_u8_1d **res;
  ERL_NIF_TERM ret;

  if(argc != 3) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[1], U8_1D, (void**) &xs)) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[2], U8_1D, (void**) &ys)) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(U8_1D, sizeof(struct futhark_u8_1d *));
  if(res == NULL) return enif_make_badarg(env);

  if (futhark_entry_add(*ctx, res, *xs, *ys) != 0) return enif_make_badarg(env);

  ret = enif_make_resource(env, res);
  enif_release_resource(res);

  return enif_make_tuple2(env, atom_ok, ret);
}

static ERL_NIF_TERM futhark_u8_1d_to_binary_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context **ctx;
  struct futhark_u8_1d **xs;

  ErlNifBinary binary;
  ERL_NIF_TERM ret;

  if(argc != 2) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
    return enif_make_badarg(env);
  }

  if(!enif_get_resource(env, argv[1], U8_1D, (void**) &xs)) {
    return enif_make_badarg(env);
  }

  const int64_t *shape = futhark_shape_u8_1d(*ctx, *xs);

  enif_alloc_binary(shape[0] * sizeof(uint8_t), &binary);

  if (futhark_values_u8_1d(*ctx, *xs, (uint8_t *)(binary.data)) != 0) return enif_make_badarg(env);
  futhark_context_sync(*ctx);

  ret = enif_make_binary(env, &binary);
  enif_release_resource(&binary);

  return enif_make_tuple2(env, atom_ok, ret);
}

static ErlNifFunc nif_funcs[] = {
  {"futhark_context_config_new", 0, futhark_context_config_new_nif},
  {"futhark_context_new", 1, futhark_context_new_nif},
  {"futhark_new_u8_1d", 2, futhark_new_u8_1d_nif},
  {"futhark_entry_add", 3, futhark_entry_add_nif},
  {"futhark_context_sync", 1, futhark_context_sync_nif},
  {"futhark_u8_1d_to_binary", 2, futhark_u8_1d_to_binary_nif}
};

ERL_NIF_INIT(Elixir.Map.NIF, nif_funcs, &load, NULL, NULL, NULL)