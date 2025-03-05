# liblcb

[![Build-macOS-latest Actions Status](https://github.com/rozhuk-im/liblcb/workflows/build-macos-latest/badge.svg)](https://github.com/rozhuk-im/liblcb/actions)
[![Build-Ubuntu-latest Actions Status](https://github.com/rozhuk-im/liblcb/workflows/build-ubuntu-latest/badge.svg)](https://github.com/rozhuk-im/liblcb/actions)


Light Code Base

Rozhuk Ivan <rozhuk.im@gmail.com> 2011-2024

Statically linked code library.
Compile and include only things that you need.


## Licence
BSD licence.


## Donate
Support the author
* **GitHub Sponsors:** [!["GitHub Sponsors"](https://camo.githubusercontent.com/220b7d46014daa72a2ab6b0fcf4b8bf5c4be7289ad4b02f355d5aa8407eb952c/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f2d53706f6e736f722d6661666266633f6c6f676f3d47697448756225323053706f6e736f7273)](https://github.com/sponsors/rozhuk-im) <br/>
* **Buy Me A Coffee:** [!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/rojuc) <br/>
* **PayPal:** [![PayPal](https://srv-cdn.himpfen.io/badges/paypal/paypal-flat.svg)](https://paypal.me/rojuc) <br/>
* **Bitcoin (BTC):** `1AxYyMWek5vhoWWRTWKQpWUqKxyfLarCuz` <br/>


## Components
* al: abstraction layer (OS, hardware)
* crypto: crypto algs
* math: mathematic functions
* net: socket and net staff
* proto: protocols implementetions
* threadpool: kqueue/epoll thread pool
* utils


## Run tests
```
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_LIBLCB_TESTS=1 ..
cmake --build . --config Release -j 16
ctest -C Release --output-on-failure -j 16
```

