# The targets live in the q workspace Makefile; `make nix` works here as it does from the q root.
ifeq ($(wildcard ../../Makefile),)
$(error not inside the q workspace: run make from its root)
endif

.DEFAULT:
	@$(MAKE) -C ../.. $@
