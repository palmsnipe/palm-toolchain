# Hello World

A minimal Palm OS application built entirely with the repository-local
toolchain. It opens one form and exits when **Done** is tapped.

From the repository root, bootstrap the toolchain once and build the example:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r3 make bootstrap
make example
```

Or build directly from this directory:

```sh
make
```

The application is produced as `build/HelloWorld.prc`. Install that file using
your Palm OS emulator's or device's normal application-install mechanism.

Useful targets:

- `make` builds the application.
- `make test` builds it and validates its PRC header and required resources.
- `make clean` removes the example's generated `build/` directory.

The files illustrate the parts required by a small application:

- `src/main.c` contains the form handler and Palm event loop.
- `src/startup.c` provides the Palm launch entry point and runtime relocation.
- `resources/app.rcp` defines the form and application metadata for PilRC.
- `linker.lkr` lays out the relocatable 68K code resource.
- `Makefile` compiles, links, creates resources, and packages the PRC.

The four-character creator ID `Helo` is for this example only. Choose a unique
creator ID before using this project as the basis of a real application.
