#include <erl_nif.h>
#include "lib_calc.h"
#include "lib_map.h"

ErlNifResourceType* RES_TYPE;
ERL_NIF_TERM atom_ok;

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
  struct futhark_context_config *cfg = futhark_context_config_new();

  ERL_NIF_TERM term = enif_make_resource(env, cfg);
  enif_release_resource(cfg);

  return term;
}


static ErlNifFunc nif_funcs[] = {
  {"somar", 2, somar_nif},
  {"subtrair", 2, subtrair_nif},
  {"multiplicar", 2, multiplicar_nif},
  {"dividir", 2, dividir_nif},
  {"futhark_context_config_new", 0, futhark_context_config_new_nif}
};

ERL_NIF_INIT(Elixir.Calc, nif_funcs, NULL, NULL, NULL, NULL)
