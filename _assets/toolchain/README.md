This is a dockerfile which allows to have a quick dev environnement for the TrimUI Smart.


It is based on [monkeyx-net/retro_builder_docker](https://github.com/monkeyx-net/retro_builder_docker/) (for the pre-built image).

And [s0ckz/trimui-smart-pro-toolchain](https://github.com/s0ckz/trimui-smart-pro-toolchain) inspiration for the Dockerfile and Makefile. 

It doesn't include the specifities of the [dedicated TrimUI SDK](https://github.com/trimui/toolchain_sdk_smartpro/releases/tag/20231018).


How to use: 
---

```
cd ./CrossMix-OS/_assets/toolchain/
sudo make shell
```