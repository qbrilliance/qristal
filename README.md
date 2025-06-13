# Quantum Brilliance Qristal SDK

Qristal is the QB software development kit for quantum computing.

## Getting Started

QB Qristal can be installed directly from source or via a pre-built Docker image.

### Docker

A Docker image is provided in the GitLab container registry associated with the SDK repository.

Depending on how you have set up Docker on your system, you may or may not need to run the following commands as root.

1. Start the QB Qristal container
```sh
docker run --rm -it --name qristal -d -p 8889:8889 registry.gitlab.com/qbau/software-and-apps/public/qbsdk/qristal-sdk
```
If your system has one or more NVIDIA GPUs, install the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) and add the switch `--gpus all` to the `docker run` command in order to use them.

This command will start a container and map its TCP port 8889 to the same port on the Docker host (your computer).

From your web browser, you can access a JupyterLab environment at http://localhost:8889 to view Python examples and start prototyping with QB Qristal.

2. Connect to the QB Qristal container

After starting the container, besides the [JupyterLab environment](http://localhost:8889), you can connect (attach) directly to the container via a terminal or VSCode.

- For the terminal, run the following command to attach to a terminal session inside the container.

```sh
docker exec -it qristal bash
```

- If you prefer to use VSCode, you can "attach" it to the  running `qristal` Docker container.

To attach to the `qristal` Docker container, either select `Dev Containers: Attach to Running Container...` from the `Command Palette` (F1) or use the `Remote Explorer` in the `Activity Bar` and from the `Containers` view, select the `Attach to Container` inline action on the container. In both methods, a dropdown will appear; select the `qristal` container.

3. Stop and remove the container

```sh
docker stop qristal
```

### Install from source

**Prerequisites**

*Bare metal*

Linux (e.g. Ubuntu) is required. One may choose to use Ubuntu with WSL 2 ([Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/)), as the installation sequence is the same. The best performance is achieved with regular Linux, due to additional overhead coming from the Windows filesystem. Please ensure if using WSL that you turn on file system case sensitivity for the location where you intend to install Qristal.

Before building Qristal, you must have the following packages already installed and working:

- Python 3.8 or later

- gcc, g++, and gfortran 11.4.0 or later. LLVM-Clang 16.0.6 or later is supported, but gcc/g++ is still required for building exatn and tnqvm.

- cmake 3.20 or later

- Boost 1.71 or later

- OpenBLAS

- OpenSSL

- Curl


For example, on Ubuntu 22.04, you can use `apt` to install all of the above:

```sh
sudo apt install build-essential cmake gfortran libboost-all-dev libcurl4-openssl-dev libssl-dev libopenblas-dev libpython3-dev python3 python3-pip
```

Qristal will be built with support for CUDA Quantum if and only if cmake detects that your system has a compatible CUDA Quantum installation.

*Dev container*

Alternatively, you can build Qristal in a development container, using the contents of `integrations/vscode/.devcontainer`.  For this, the only prerequisites are

- Docker

- an IDE compliant with the Development Container Specification (e.g. VS Code)


**Compilation**

<a name="compilation"></a>

After cloning the Qristal SDK repository, compile and install it with

```sh
mkdir build && cd build
cmake .. -DINSTALL_MISSING=ON
make -j$(nproc) install
```

This will automatically install all missing dependencies neither covered by the `apt` commands above nor provided by the dev container. If you wish to only install missing C++ or Python dependencies, instead of passing `-DINSTALL_MISSING=ON` you can pass `-DINSTALL_MISSING=CXX` or `-DINSTALL_MISSING=PYTHON`.

Note that the dependencies to be installed include the constituent Qristal components `core`, `decoder` and `integrations`.  By default, the latest tagged releases of each of these components is pulled in. If you would like cmake to retrieve alternative versions of these components, you can specify a git ref to pull in each case, by passing `-DCORE_TAG=<YOUR_TAG>`, `-DDECODER_TAG=<YOUR_TAG>` and/or `-DINTEGRATIONS_TAG=<YOUR_TAG>` when invoking cmake. Note that for the overall build to be successful, the refs of the different components, including the top-level Qristal SDK repo itself, must correspond to versions that are compatible with one another. You can always achieve this by using the same release tag (e.g. `v1.6.0`) for everything, or simply `main`, which will refer to the tips of all `main` branches.

By default, the public Qristal git repositories are used to retrieve each of these components. If you have access to and prefer to use the development repositories, you can pass `--preset=dev` when invoking cmake. Note that private repos contain refs not present in the public repos, so forgetting to include the `dev` preset can lead to errors about missing refs.

If you wish to build Qristal's C++ noise-aware circuit placement routines, you must also enable the use of the additional dependency [TKET](https://github.com/CQCL/tket). This is done by passing `-DWITH_TKET=ON` to `cmake`. TKET will be installed automatically by `cmake` if both `-DWITH_TKET=ON` and `-DINSTALL_MISSING=ON` (or `-DINSTALL_MISSING=CXX`) are passed to `cmake`. Alternatively, if you have an existing TKET installation, you can pass `-DWITH_TKET=ON -DTKET_DIR=<YOUR TKET INSTALLATION DIR>` to `cmake` to tell it to use your installation rather than building TKET from source.

If you also wish to build the html documentation, you can pass `-DBUILD_DOCS=ON` to `cmake`.

When using QB Qristal, a user workflow normally consists of the following steps:

- Define a quantum circuit, for example, as an OpenQASM source string.

- Configure the QB Qristal runtime, e.g., the accelerator backend, number of measurement shots, etc.

- Run the circuit with the specified configurations.

- Retrieve and analyze the results of the experiments.

Here is an example of the entire workflow:

```python
# Import the core of the QB SDK
import qristal.core

# Create a quantum computing session using the QB SDK
my_sim = qristal.core.session()

# Choose a simulator backend
my_sim.acc = "qpp"

# Choose how many qubits to simulate
my_sim.qn = 2

# Choose how many 'shots' to run through the circuit
my_sim.sn = 100

# Define the quantum program to run (aka 'quantum kernel' aka 'quantum circuit')
my_sim.instring = '''
__qpu__ void MY_QUANTUM_CIRCUIT(qreg q)
{
  OPENQASM 2.0;
  include "qelib1.inc";
  creg c[2];
  h q[0];
  cx q[0], q[1];
  measure q[1] -> c[1];
  measure q[0] -> c[0];
}
'''

# Run the circuit 100 times and count up the results in each of the classical registers
print("About to run quantum program...")
my_sim.run()
print("Ran successfully!")

# Print the cumulative results in each of the classical registers
print("Results:\n", my_sim.results)
```

If you run the example, you will get an output similar to the following (right-hand values will both be around 50):

```sh
About to run quantum program...
Ran successfully!
Results:
 {
    "00": 45,
    "11": 55
}
```

## Further examples ##

Following installation, you can find

- A series of examples in the installed folder `examples`.  These are described [here](examples/README.md).
- A detailed set of introductory exercises in the `exercises` folder.  These can be launched using Jupyter Notebook.
- A standalone [Quantum Decoder application](docs/README_decoder.md).

## Documentation
You can find the docs for Qristal on the web at [qristal.readthedocs.io](https://qristal.readthedocs.io).  If you have built and installed the documentation (see [compilation](#compilation)), you can also find it at `<installation_directory>/docs/html/index.html`.

## License ##
[Apache 2.0](LICENSE)
