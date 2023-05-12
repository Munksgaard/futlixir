#include <erl_nif.h>
#include "lib_calc.h"
#include "lib_map.h"

ErlNifResourceType* CONFIG_TYPE;
ERL_NIF_TERM atom_ok;


static int open_resource(ErlNifEnv* env)
{
    const char* mod = "resources";
    const char* name = "Config";
    int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

    CONFIG_TYPE = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
    if(CONFIG_TYPE == NULL) return -1;
    return 0;
}


static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
    if(open_resource(env) == -1) return -1;

    atom_ok = enif_make_atom(env, "ok");

    return 0;
}

static ERL_NIF_TERM somar_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int a, b, result;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[1], &b);
  result = somar(a, b);
  return enif_make_int(env, result);
}

static ERL_NIF_TERM subtrair_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int a, b, result;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[1], &b);
  result = subtrair(a, b);
  return enif_make_int(env, result);
}

static ERL_NIF_TERM multiplicar_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int a, b, result;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[1], &b);
  result = multiplicar(a, b);
  return enif_make_int(env, result);
}

static ERL_NIF_TERM dividir_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int a, b, result;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[1], &b);
  result = dividir(a, b);
  return enif_make_int(env, result);
}

static ERL_NIF_TERM futhark_context_config_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  struct futhark_context_config *res;

  ERL_NIF_TERM ret;
  unsigned int id;

  if(argc != 0) {
    return enif_make_badarg(env);
  }

  res = enif_alloc_resource(CONFIG_TYPE, sizeof(struct futhark_context_config*));
  if(res == NULL) return enif_make_badarg(env);

  ret = enif_make_resource(env, res);

  struct futhark_context_config* tmp = futhark_context_config_new();
  res = tmp;

  return enif_make_tuple2(env, atom_ok, ret);
}

static ErlNifFunc nif_funcs[] = {
  {"somar", 2, somar_nif},
  {"subtrair", 2, subtrair_nif},
  {"multiplicar", 2, multiplicar_nif},
  {"dividir", 2, dividir_nif},
  {"futhark_context_config_new", 0, futhark_context_config_new_nif}
};

ERL_NIF_INIT(Elixir.Calc, nif_funcs, &load, NULL, NULL, NULL)
