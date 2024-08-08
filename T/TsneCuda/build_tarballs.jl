using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "tsne_cuda"
version = v"3.0.1"

sources = [
    GitSource("https://github.com/CannyLab/tsne-cuda.git", "2dad49713ba451c0953b646a85ac2567b5d1070e")
]

script = raw"""
export CUDA_ARCHS="60;70;80"

export CUDA_HOME="$prefix/cuda"
export CUDA_BIN_PATH="$CUDA_HOME/bin"
export CUDA_LIB_PATH="$CUDA_HOME/lib64"
export CUDA_INC_PATH="$CUDA_HOME/include"
PATH="$PATH:$CUDA_BIN_PATH"

cd ${WORKSPACE}/srcdir/tsne-cuda

git submodule init
git submodule update

mkdir -p build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCUDA_ARCHITECTURES="$CUDA_ARCHS" \
    -DCUDA_TOOLKIT_ROOT_DIR="$CUDA_HOME" \
    -DCMAKE_CUDA_COMPILER="$CUDA_BIN_PATH/nvcc" \
    ..

make -j${nproc}
"""

products = [
    LibraryProduct("tsnecuda", :tsnecuda),
]

augment_platform_block = CUDA.augment

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

print(platforms)

for platform in platforms[2:3]
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=v"8",
                   julia_compat="1.8",
                   augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end
