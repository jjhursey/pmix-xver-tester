## PMIx Cross-Version Testing Environment

The Docker container environment defined in this project is useful when testing
cross-version compatability in PMIx. It supports the ability to test the current
release branches against each other, but also add in your branch to the testing
mechanism.

This Docker image contains prebuilt installs for each of the release branches.

The `/home/pmixer/bin/run-xversion.sh` script will automatically detect if those
prebuild installs are out of date and update them if necessary. If they reflect
the current HEAD of development then no rebuild is triggered (thus speeding up
the testing cycle).

After building this script will then run the `xversion.py` script to check
PMIx client/server cross-version compatability. If any combination fails
then the script will return a non-zero value indicating failure.

If you are doing a lot of interative development that requires checking cross-version
compatability you may want to make a persistent container, and rerun the script
within the same container. This will prevent an older Docker image from rebuilding
the release installs everytime you run the container.


### Run baseline cross-version compatability

To compare the current release branches (and `master`) to each other simply run:

```
docker pull jjhursey/pmix-xver-tester
docker run pmix-xver-tester
```


### Run with a specific topic branch

To compare the baseline against a topic branch run (make sure to use the `https` repo address):

```
docker run pmix-xver-tester /home/pmixer/bin/run-xversion.sh \
       --repo https://github.com/USERNAME/pmix.git --branch my-topic-branch
```


### Run with a path, volume mounted in

To compare the baseline against a local build directory just volume mount it in, and use the `--path` option to point to the location inside the container.

```
docker run -v $PWD/my-local-branch:/home/pmixer/my-branch pmix-xver-tester \
       /home/pmixer/bin/run-xversion.sh --path /home/pmixer/my-branch
```
