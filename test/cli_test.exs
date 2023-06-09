defmodule CliTest do
  use ExUnit.Case

  doctest Futlixir.CLI

  test "lib_map.json" do
    tmp_dir = System.tmp_dir()
    tmp_file = Path.join([tmp_dir, "lib_map.json"])

    File.write!(tmp_file, ~S"""
    {
      "backend": "opencl",
      "entry_points": {
        "add": {
          "cfun": "futhark_entry_add",
          "inputs": [
            {
              "name": "xs",
              "type": "[]u8",
              "unique": false
            },
            {
              "name": "ys",
              "type": "[]u8",
              "unique": false
            }
          ],
          "outputs": [
            {
              "type": "[]u8",
              "unique": false
            }
          ],
          "tuning_params": [
            "add.segmap_group_size_6879"
          ]
        },
        "add_i64": {
          "cfun": "futhark_entry_add_i64",
          "inputs": [
            {
              "name": "xs",
              "type": "[]i64",
              "unique": false
            },
            {
              "name": "ys",
              "type": "[]i64",
              "unique": false
            }
          ],
          "outputs": [
            {
              "type": "[]i64",
              "unique": false
            }
          ],
          "tuning_params": [
            "add_i64.segmap_group_size_6899"
          ]
        }
      },
      "types": {
        "[]i64": {
          "ctype": "struct futhark_i64_1d *",
          "elemtype": "i64",
          "kind": "array",
          "ops": {
            "free": "futhark_free_i64_1d",
            "new": "futhark_new_i64_1d",
            "shape": "futhark_shape_i64_1d",
            "values": "futhark_values_i64_1d"
          },
          "rank": 1
        },
        "[]u8": {
          "ctype": "struct futhark_u8_1d *",
          "elemtype": "u8",
          "kind": "array",
          "ops": {
            "free": "futhark_free_u8_1d",
            "new": "futhark_new_u8_1d",
            "shape": "futhark_shape_u8_1d",
            "values": "futhark_values_u8_1d"
          },
          "rank": 1
        }
      },
      "version": "0.25.0 (prerelease - include info below when reporting bugs)\ngit: 6a2e6e1 (Sun Apr 30 19:03:19 2023 +0200) [modified]"
    }
    """)

    Futlixir.CLI.main([tmp_file, "Map.NIF"])

    assert File.read!(Path.join([tmp_dir, "lib_map.ex"])) == """
           defmodule Map.NIF do
             @on_load :load_nifs

             def load_nifs do
               :erlang.load_nif('./#{tmp_dir}/lib_map_nif', 0)
             end

             def futhark_context_config_new do
               raise "NIF futhark_context_config_new not implemented"
             end

             def futhark_context_new(_cfg) do
               raise "NIF futhark_context_new not implemented"
             end

             def futhark_context_sync(_ctx) do
               raise "NIF futhark_context_sync not implemented"
             end

             def futhark_new_i64_1d(_ctx, _binary) do
               raise "NIF futhark_new_i64_1d not implemented"
             end

             def futhark_i64_1d_to_binary(_ctx, _in) do
               raise "NIF futhark_i64_1d_to_binary not implemented"
             end

             def futhark_new_u8_1d(_ctx, _binary) do
               raise "NIF futhark_new_u8_1d not implemented"
             end

             def futhark_u8_1d_to_binary(_ctx, _in) do
               raise "NIF futhark_u8_1d_to_binary not implemented"
             end

             def futhark_entry_add(_ctx, _xs, _ys) do
               raise "NIF futhark_entry_add not implemented"
             end

             def futhark_entry_add_i64(_ctx, _xs, _ys) do
               raise "NIF futhark_entry_add_i64 not implemented"
             end

           end
           """

    assert File.read!(Path.join([tmp_dir, "lib_map_nif.c"])) == """
           #include <erl_nif.h>
           #include "#{tmp_dir}/lib_map.c"

           struct futhark_context;

           ERL_NIF_TERM atom_ok;

           ErlNifResourceType* CONFIG_TYPE;
           ErlNifResourceType* CONTEXT_TYPE;

           ErlNifResourceType* I64_1D;
           ErlNifResourceType* U8_1D;

           static int open_resource(ErlNifEnv* env, ErlNifResourceType** resource_type, const char* name)
           {
             const char* mod = "resources";
             int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

             *resource_type = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
             if(CONFIG_TYPE == NULL) return -1;
             return 0;
           }

           static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
           {
             if(open_resource(env, &CONFIG_TYPE, "Config") == -1) return -1;
             if(open_resource(env, &CONTEXT_TYPE, "Context") == -1) return -1;
             if(open_resource(env, &I64_1D, "i64_1d") == -1) return -1;
             if(open_resource(env, &U8_1D, "u8_1d") == -1) return -1;

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

           static ERL_NIF_TERM futhark_new_i64_1d_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
           {
             struct futhark_context **ctx;
             ErlNifBinary bin;

             struct futhark_i64_1d **res;
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

             res = enif_alloc_resource(I64_1D, sizeof(struct futhark_i64_1d *));
             if(res == NULL) return enif_make_badarg(env);

             struct futhark_i64_1d * tmp = futhark_new_i64_1d(*ctx, (const int64_t *)bin.data, bin.size / sizeof(int64_t));
             const int64_t *shape = futhark_shape_i64_1d(*ctx, tmp);

             *res = tmp;

             ret = enif_make_resource(env, res);
             enif_release_resource(res);

             return enif_make_tuple2(env, atom_ok, ret);
           }

           static ERL_NIF_TERM futhark_i64_1d_to_binary_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
           {
             struct futhark_context **ctx;
             struct futhark_i64_1d **xs;

             ErlNifBinary binary;
             ERL_NIF_TERM ret;

             if(argc != 2) {
               return enif_make_badarg(env);
             }

             if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
               return enif_make_badarg(env);
             }

             if(!enif_get_resource(env, argv[1], I64_1D, (void**) &xs)) {
               return enif_make_badarg(env);
             }

             const int64_t *shape = futhark_shape_i64_1d(*ctx, *xs);

             enif_alloc_binary(shape[0] * sizeof(int64_t), &binary);

             if (futhark_values_i64_1d(*ctx, *xs, (int64_t *)(binary.data)) != 0) return enif_make_badarg(env);
             futhark_context_sync(*ctx);

             ret = enif_make_binary(env, &binary);

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

             struct futhark_u8_1d * tmp = futhark_new_u8_1d(*ctx, (const uint8_t *)bin.data, bin.size / sizeof(uint8_t));
             const int64_t *shape = futhark_shape_u8_1d(*ctx, tmp);

             *res = tmp;

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

             return enif_make_tuple2(env, atom_ok, ret);
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

           static ERL_NIF_TERM futhark_entry_add_i64_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
           {
             struct futhark_context **ctx;

             struct futhark_i64_1d **xs;
             struct futhark_i64_1d **ys;

             struct futhark_i64_1d **res;

             ERL_NIF_TERM ret;

             if(argc != 3) {
               return enif_make_badarg(env);
             }

             if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
               return enif_make_badarg(env);
             }

             if(!enif_get_resource(env, argv[1], I64_1D, (void**) &xs)) {
               return enif_make_badarg(env);
             }

             if(!enif_get_resource(env, argv[2], I64_1D, (void**) &ys)) {
               return enif_make_badarg(env);
             }

             res = enif_alloc_resource(I64_1D, sizeof(struct futhark_i64_1d *));
             if(res == NULL) return enif_make_badarg(env);

             if (futhark_entry_add_i64(*ctx, res, *xs, *ys) != 0) return enif_make_badarg(env);

             ret = enif_make_resource(env, res);
             enif_release_resource(res);

             return enif_make_tuple2(env, atom_ok, ret);
           }

           static ErlNifFunc nif_funcs[] = {
             {"futhark_context_config_new", 0, futhark_context_config_new_nif},
             {"futhark_context_new", 1, futhark_context_new_nif},

             {"futhark_new_i64_1d", 2, futhark_new_i64_1d_nif},
             {"futhark_i64_1d_to_binary", 2, futhark_i64_1d_to_binary_nif},
             {"futhark_new_u8_1d", 2, futhark_new_u8_1d_nif},
             {"futhark_u8_1d_to_binary", 2, futhark_u8_1d_to_binary_nif},
             {"futhark_entry_add", 3, futhark_entry_add_nif},
             {"futhark_entry_add_i64", 3, futhark_entry_add_i64_nif},
             {"futhark_context_sync", 1, futhark_context_sync_nif}
           };

           ERL_NIF_INIT(Elixir.Map.NIF, nif_funcs, &load, NULL, NULL, NULL)
           """
  end
end
